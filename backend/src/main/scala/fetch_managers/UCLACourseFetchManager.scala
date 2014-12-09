package fetch_managers

import com.typesafe.scalalogging.slf4j.LazyLogging
import course_refresh.NodeSeqUtilities._
import course_refresh.StringUtilities._
import course_refresh.{HTTPManager, HTTPRequestFactory, SchoolManager}
import model._

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.util.control.NonFatal
import scala.util.{Failure, Success, Try}
import scala.xml.{Node, NodeSeq}


class UCLACourseFetchManager(term: String) extends SchoolManager with LazyLogging {
  private val UCLARequestFactory: HTTPRequestFactory = new HTTPRequestFactory("http://www.registrar.ucla.edu/schedule")

  override def fetchDepartments: Future[Seq[Department]] = HTTPManager.withHTTPManager { httpManager =>
    httpManager.execute(UCLARequestFactory("/schedulehome.aspx")) { nodeSeq: NodeSeq =>
      val departmentNodes: NodeSeq = (nodeSeq \\ "select").filterByLiteralAttribute("id", "ctl00_BodyContentPlaceHolder_SOCmain_lstSubjectArea") \\ "option"
      require(departmentNodes.length > 0, "Wasn't able to find the list of departments")
      departmentNodes map { node: Node =>
        val schoolSpecificId = node.attribute("value").get.text
        val name = node.text
        Department(SchoolId.UCLA, schoolSpecificId, name)
      }
    }
  }

  override def fetchCourses(department: Department): Future[Seq[Course]] = HTTPManager.withHTTPManager { httpManager =>
    val coursesRequest = UCLARequestFactory("/crsredir.aspx", "GET", Map("termsel" -> term, "subareasel" -> department.schoolSpecificId))
    httpManager.execute(coursesRequest) { nodeSeq =>
      val courseNodes: NodeSeq = (nodeSeq \\ "select").filterByLiteralAttribute("id", "ctl00_BodyContentPlaceHolder_crsredir1_lstCourseNormal") \\ "option"
      courseNodes.zipWithIndex map { case (node: Node, index: Int) =>
        val departmentSpecificCourseId :: courseName :: _ = node.text.split(" - ", 2).toList
        val request = UCLARequestFactory(
          path = "/detselect.aspx",
          method = "GET",
          queryParams = Map("termsel" -> term, "subareasel" -> department.schoolSpecificId, "idxcrs" -> node.attribute("value").get.text)
        )
        Course(SchoolId.UCLA, department.primaryKey, departmentSpecificCourseId, courseName, index, httpManager.reqFromHTTPRequest(request).url)
      }
    }
  }

  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = HTTPManager.withHTTPManager { httpManager =>
    val sectionFutures: Seq[Future[Seq[(Section, Seq[Event])]]] = courses map { course: Course =>
      httpManager.get(course.context) { nodeSeq: NodeSeq =>
        val tables = nodeSeq \\ "table"
        val sectionNodes: NodeSeq = tables.filterByAttributePrefix("id", "dgdLectureHeader")
        val sectionNameRegex = "^ctl00_BodyContentPlaceHolder_detselect_dgdLectureHeader.*_ctl02_lblGenericMessage$"
        val staffRegex = "^ctl00_BodyContentPlaceHolder_detselect_dgdLectureHeader.*_ctl02_lblGenericMessage2$"
        val sections = sectionNodes map { sectionNode: Node =>
          val sectionNodes: NodeSeq = sectionNode \\ "span"
          val sectionName: String = sectionNodes.filterByAttribute("id", _.matches(sectionNameRegex))(0).text
          val staff: String = sectionNodes.filterByAttribute("id", _.matches(staffRegex)).text
            .replaceAllLiterally("\u00a0", "")
            .replaceAll(" {2,}", "")
            .trim()
          Section(
            sectionName,
            staff,
            course.primaryKey,
            course.schoolId
          )
        }

        val eventTables = tables.filterByLiteralAttribute("class", "dgdTemplateGrid").filterByLackOfAttribute("id")
        val sectionsAndEventHtml: Seq[(Section, Node)] = sections zip eventTables
        val idLinkRegex = """^subdet\.aspx\?srs=(\d*)\&term=.*""".r
        sectionsAndEventHtml map { case (section: Section, eventTable: Node) =>
          val eventRows = (eventTable \\ "tr").filterByLackOfAttribute("class")
          val events = eventRows flatMap { eventRow: Node =>
            val eventAttributeCells = (eventRow \\ "td").filterByAttribute("class", _ != "dgdClassDataColumnSpacer")
            val schoolSpecificEventIdCell = eventAttributeCells.filterByLiteralAttribute("class", "dgdClassDataColumnIDNumber")
            val idLinks = schoolSpecificEventIdCell \\ "a"
            require(idLinks.length <= 1, {
              logger.error(s"There are too many id links in eventRow: $eventRow")
            })
            val id: Option[String] = if (idLinks.length == 1) {
              val idLink: String = idLinks(0).attribute("href").get.text

              val courseId: String = idLink match {
                case idLinkRegex(idString) => idString
                case _ => throw new Exception(s"Unable to extract the event id from the link: $idLink")
              }
              Option(courseId)
            } else {
              None
            }
            val eventTry = Try {
              val eventType = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataActType")
              val sectionNo = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataSectionNumber")
              val status = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataStatus")
              val numEnrolled = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataEnrollTotal").safeToInt
              val enrollmentCap = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataEnrollCap").safeToInt
              val numWaitlisted = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataWaitListTotal").safeToInt
              val waitlistCap = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataWaitListCap").safeToInt
              val weekdays = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataDays")
              val startTime = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataTimeStart")
              val endTime = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataTimeEnd")
              val building = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataBuilding")
              val room = getFirstTextInsideFirstNodeOfClass(eventAttributeCells, "dgdClassDataRoom")
              Event(
                id,
                s"$eventType $sectionNo",
                Seq(Spacetime(weekdays, s"$startTime - $endTime", s"$building $room")),
                numEnrolled,
                enrollmentCap,
                numWaitlisted,
                waitlistCap,
                status,
                section.primaryKey,
                SchoolId.UCLA
              )
            }
            eventTry match {
              case Success(event) => Some(event)
              case Failure(t) =>
                logger.warn(s"Unable to update one of the events for section $section. Event row: $eventRow.", t)
                None
            }
          }

          val finalEvents = events.foldLeft(Seq[Event]()) { (accumulator: Seq[Event], event: Event) =>
            event.schoolSpecificEventId match {
              case Some(schoolSpecificEventId) => accumulator :+ event
              case None =>
                val prevEvent: Event = accumulator.last
                val eventWithCombinedTimesAndLocations = prevEvent.copy(
                  timesAndLocations = prevEvent.timesAndLocations ++ event.timesAndLocations
                )
                accumulator.slice(0, accumulator.length - 1) :+ eventWithCombinedTimesAndLocations
            }
          }
          (section, finalEvents)
        }
      }
    }
    Future.sequence(sectionFutures).map(_.flatten)
  }

  private def getFirstTextInsideFirstNodeOfClass(nodeSeq: NodeSeq, classString: String): String = {
    try {
      val strings = nodeSeq.filterByLiteralAttribute("class", classString)(0) flatMap { node: Node =>
        val content = node.text
        if (content != "")
          Some(content.trim)
        else
          None
      }
      strings(0)
    } catch {
      case NonFatal(t) =>
        logger.warn(s"Unable to get the text node inside the first node of class <$classString>. Here's the node:\n$nodeSeq", t)
      ""
    }
  }


}
