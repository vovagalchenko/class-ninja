package sjsu

import com.typesafe.scalalogging.slf4j.LazyLogging
import course_refresh.{HTTPRequestFactory, HTTPManager, SchoolManager}
import course_refresh.NodeSeqUtilities._
import model.SchoolId
import model._
import scala.slick.driver.MySQLDriver.simple._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.xml.NodeSeq
import course_refresh.StringUtilities._

class SJSUCourseFetchManager(term: String)(implicit dbManager: DBManager, dbSession: Session) extends SchoolManager with LazyLogging {
  private val SJSURequestFactory: HTTPRequestFactory = new HTTPRequestFactory("https://cmshr.cms.sjsu.edu/psc/HSJPRDF/EMPLOYEE/HSJPRD/c/COMMUNITY_ACCESS.CLASS_SEARCH.GBL")

  override def fetchDepartments: Future[Seq[Department]] = withCookies { httpManager =>
    val firstDepartmentsPage = httpManager.execute(SJSURequestFactory("", Map("ICAction" -> "CLASS_SRCH_WRK2_SSR_PB_SUBJ_SRCH$0"))) { o => o }
    firstDepartmentsPage flatMap { letterANodeSeq =>
      // Starting with B, because the A is included in letterANodeSeq
      val departmentFutures = (('B' to 'Z') ++ ('0' to '9')) map { character: Char =>
        httpManager.execute(SJSURequestFactory("", Map("ICAction" -> s"SSR_CLSRCH_WRK2_SSR_ALPHANUM_$character")))(pageToDepartment)
      }
      (Future sequence (departmentFutures :+ Future(pageToDepartment(letterANodeSeq)))).map(_.flatten)
    }
  }

  private def pageToDepartment(page: NodeSeq): Seq[Department] = {
    val departmentNodes = (page \\ "table").filterByLiteralAttribute("id", "ACE_SSR_CLSRCH_SUBJ$0") \\ "tr"
    val optionalDepartments = departmentNodes map { deptNode =>
      val spans = deptNode \\ "span"
      val schoolSpecificIdNode = spans.filterByAttributePrefix("id", "SSR_CLSRCH_SUBJ_SUBJECT$")
      val departmentNameNode = spans.filterByAttributePrefix("id", "SUBJECT_TBL_DESCRFORMAL$")
      val sanitizedDepartmentName = sanitizeString(departmentNameNode.text)
      val sanitizedSchoolSpecificId = sanitizeString(schoolSpecificIdNode.text)
      if (schoolSpecificIdNode.size == 1 && departmentNameNode.size == 1)
        Some(Department(
          SchoolId.SJSU,
          sanitizedSchoolSpecificId,
          if (sanitizedDepartmentName.length > 0) sanitizedDepartmentName else sanitizedSchoolSpecificId
        ))
      else None
    }
    optionalDepartments.flatten
  }

  override def fetchCourses(department: Department): Future[Seq[Course]] = withDepartmentCookies(department) { case (httpManager, courseListNodeSeq) =>
    Future {
      val courseNodes = (courseListNodeSeq \\ "div").filterByAttributePrefix("id", "win0divSSR_CLSRSLT_WRK_GROUPBOX2GP$")
      val courses = courseNodes.zipWithIndex map { case (courseNode, index) =>
        val departmentSpecificCourseId :: courseName :: _ = courseNode.text.split(" - ", 2).toList.map(sanitizeString)
        Course(
          department.schoolId,
          department.primaryKey,
          departmentSpecificCourseId,
          courseName,
          index,
          ""
        )
      }
      courses
    }
  }

  private val daysOfWeekMap = Map(
    "Mo" -> "M",
    "Tu"  -> "T",
    "We"  -> "W",
    "Th"  -> "R",
    "Fr"  -> "F",
    "Sa" -> "S"
  )

  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = {
    val departments = dbManager.departments
      .filter(_.departmentId inSet courses.map(_.departmentId).distinct)
      .list
    val sequenceOfFutureSequences = departments map { department =>
      withDepartmentCookies(department) { case (httpManager, courseListing) =>
        val eventLinks = (courseListing \\ "a").filterByAttributePrefix("id", "MTG_CLASS_NBR$")
        val sequenceOfFutureSectionsAndEvents: Seq[Future[(Section, Seq[Event])]] = eventLinks map { eventLink =>
          val classEventId = eventLink.attribute("id").get.head.text
          withDepartmentCookies(department) { case (eventHttpManager, _) =>
            eventHttpManager.execute(SJSURequestFactory("", Map("ICAction" -> classEventId))) { eventsNodeSeq =>
              val spans = eventsNodeSeq \\ "span"
              val title = spans.filterByLiteralAttribute("id", "DERIVED_CLSRCH_DESCR200").text
              val subtitle = spans.filterByLiteralAttribute("id", "DERIVED_CLSRCH_SSS_PAGE_KEYDESCR").text
              val departmentSpecificCourseId = sanitizeString("^(.*)? - ".r.findFirstMatchIn(title).get.subgroups(0))
              val sectionNumber = "\u00A0.+ - (\\d+)\u00A0{2}".r.findFirstMatchIn(title) match {
                case Some(regexMatch) => regexMatch.subgroups(0)
                case None             => "00"
              }
              val sectionType = subtitle.split(" \\| ", 3)(2)
              val sectionName = s"$sectionType $sectionNumber"
              val staff = sanitizeString(spans.filterByLiteralAttribute("id", "MTG_INSTR$0").text)
              val section = Section(
                sectionName,
                staff,
                s"${department.primaryKey}_$departmentSpecificCourseId".toSafeId,
                SchoolId.SJSU
              )
              val schoolSpecificEventId = spans.filterByLiteralAttribute("id", "SSR_CLS_DTL_WRK_CLASS_NBR").text
              val enrollmentCap = spans.filterByLiteralAttribute("id", "SSR_CLS_DTL_WRK_ENRL_CAP").text.toInt
              val numEnrolled = spans.filterByLiteralAttribute("id", "SSR_CLS_DTL_WRK_ENRL_TOT").text.toInt
              val waitListCap = spans.filterByLiteralAttribute("id", "SSR_CLS_DTL_WRK_WAIT_CAP").text.toInt
              val numWaitlisted = spans.filterByLiteralAttribute("id", "SSR_CLS_DTL_WRK_WAIT_TOT").text.toInt
              val statusImageAlt = ((eventsNodeSeq \\ "div").filterByLiteralAttribute("id", "win0divSSR_CLS_DTL_WRK_SSR_STATUS_LONG") \\ "img")
                .head
                .attribute("alt")
                .get
                .head
                .text
              val status = if (statusImageAlt == "Open" || statusImageAlt == "Closed") statusImageAlt
              else if (statusImageAlt == "Wait List") "W-List"
              else "Unknown"
              val scheduleTable = (eventsNodeSeq \\ "table").filterByLiteralAttribute("id", "SSR_CLSRCH_MTG$scroll$0")
              val timesAndLocations = (scheduleTable \\ "tr").filterByAttributePrefix("id", "trSSR_CLSRCH_MTG$0_") flatMap { scheduleRow =>
                val scheduleSpans = scheduleRow \\ "span"
                val weekdayAndTimeText = scheduleSpans.filterByAttributePrefix("id", "MTG_SCHED$").text
                val weekdayAndTime = weekdayAndTimeText.split(" ", 2)
                val room = scheduleSpans.filterByAttributePrefix("id", "MTG_LOC$").text
                if (weekdayAndTime.length == 2) {
                  val weekdays = daysOfWeekMap.foldLeft(weekdayAndTime(0)) { case (acc: String, replacement: (String, String)) =>
                    acc.replaceFirst(replacement._1, replacement._2)
                  }
                  Some(Spacetime(weekdays, weekdayAndTime(1), room))
                } else {
                  None
                }
              }

              val event = Event(
                Some(schoolSpecificEventId),
                sectionType,
                timesAndLocations,
                numEnrolled,
                enrollmentCap,
                numWaitlisted,
                waitListCap,
                status,
                section.primaryKey,
                SchoolId.SJSU
              )
              (section, Seq(event))
            }
          }
        }
        Future sequence sequenceOfFutureSectionsAndEvents
      }
    }
    Future.sequence(sequenceOfFutureSequences).map(_.flatten)
  }

  private def sanitizeString(str: String) = str
    .replaceAll("<br>", " ")
    .replaceAll("\u00A0", " ")
    .trim
    .replaceAll("\\s{2,}", " ")

  private def withDepartmentCookies[T](department: Department)(work: (HTTPManager, NodeSeq) => Future[T]): Future[T] = {
    withCookies { httpManager =>
      val courseSearchArgs = Map(
        "ICAction" -> "CLASS_SRCH_WRK2_SSR_PB_CLASS_SRCH",
        "ICSID" -> "huapZ1Ie+I1nK/HYIZlojy25t18hlwXJ0ZwvTP2RuRQ="
      )
      val futureCourseListing = httpManager.execute(SJSURequestFactory("", courseSearchArgs ++ Map(
        "SSR_CLSRCH_WRK_SUBJECT$0" -> department.schoolSpecificId,
        "CLASS_SRCH_WRK2_STRM$45$" -> term
      ))) { o => o}
      futureCourseListing flatMap { nodeSeq =>
        val bigSearchText = (nodeSeq \\ "span").filterByLiteralAttribute("id", "DERIVED_SSE_DSP_SSR_MSG_TEXT")
        if (bigSearchText.size == 1) {
          // When there are more than 50 search results, we have to make a request with ICAction=#ICSave to prime the cookies first
          // and then use the same cookies to make a request with the normal courseSearchArgs to get the actual class listing.
          val cookieFetch = httpManager.execute(SJSURequestFactory("", courseSearchArgs ++ Map("ICAction" -> "#ICSave"))) { o => o}
          cookieFetch flatMap { _ =>
            val futureCourseListing = httpManager.execute(SJSURequestFactory("", courseSearchArgs)) { o => o }
            futureCourseListing flatMap { courseListing => work(httpManager, courseListing) }
          }
        } else {
          work(httpManager, nodeSeq)
        }
      }

    }
  }

  private def withCookies[T](work: HTTPManager => Future[T]): Future[T] = HTTPManager.withHTTPManager(manageCookies = true) { httpManager =>
    val cookieFetcher = httpManager.execute(SJSURequestFactory("", "GET"))(o => o)
    cookieFetcher.flatMap { _ =>
      work(httpManager)
    }
  }
}
