package fetch_managers

import com.typesafe.scalalogging.slf4j.LazyLogging
import course_refresh.{HTTPRequestFactory, HTTPManager, SchoolManager}
import model._
import course_refresh.NodeSeqUtilities._
import course_refresh.StringUtilities._
import scala.concurrent.Future
import scala.xml.Node
import scala.pickling._
import json._

class DavisCourseFetchManager(term: String) extends SchoolManager with LazyLogging {
  private val DavisRequestFactory: HTTPRequestFactory = new HTTPRequestFactory("https://registrar.ucdavis.edu/courses/search/")

  override def fetchDepartments: Future[Seq[Department]] = HTTPManager.withHTTPManager(manageCookies = true) { httpManager =>
    httpManager.execute(DavisRequestFactory("index.cfm")) { page =>
      val subjectSelect = (page \\ "select").filterByLiteralAttribute("name", "subject")
      (subjectSelect \\ "option") flatMap { optionNode =>
        val optionalDepartmentCode = optionNode.attribute("value").map(_.head.text)
        optionalDepartmentCode.fold {
          logger.warn("Encountered a department option without a value attribute.")
          None: Option[Department]
        } { departmentCode =>
          if (departmentCode.length == 3) {
            val departmentName = optionNode.text.replaceFirst(s" \\($departmentCode\\)$$", "")
            Some(
              Department(
                schoolId = SchoolId.Davis,
                schoolSpecificId = departmentCode,
                name = departmentName
              )
            )
          } else {
            None
          }
        }
      }
    }
  }

  override def fetchCourses(department: Department): Future[Seq[Course]] = HTTPManager.withHTTPManager(manageCookies = true) { httpManager =>
    val bodyParams = Map("subject" -> department.schoolSpecificId, "termCode" -> term)
    httpManager.execute(DavisRequestFactory("course_search_results_mod8.cfm", bodyParams)) { page =>
      val coursesTable = (page \\ "table").filterByLiteralAttribute("id", "mc_win")
      val courseRows = (coursesTable \\ "tr").filterByPresenceOfAttributes("onmouseout" :: "onmouseover" :: Nil)
      val eventsTuples = courseRows map { courseRow =>
        val Seq(_, courseIdAndLocationCell, sectionAndSeatsAvailableCell, courseNameAndCreditsCell, _, courseLinkCell, _) = (courseRow \\ "td").theSeq
        def getFirstTextFromCell(cell: Node) = cell.descendant(0).text.removeExtraneousSpacing
        val courseId = getFirstTextFromCell(courseIdAndLocationCell)
        val courseName = getFirstTextFromCell(courseNameAndCreditsCell)
        val sectionName = getFirstTextFromCell(sectionAndSeatsAvailableCell)
        val courseJavascriptLink = (courseLinkCell \\ "a").head.attribute("href").map(_.text).get
        val courseLink = """'(course\.cfm\?.*)'""".r.findFirstMatchIn(courseJavascriptLink) match {
          case Some(regexMatch) => regexMatch.subgroups(0)
          case None             => throw new IllegalStateException(s"Encountered an event detail javascript link with unexpected format: $courseJavascriptLink")
        }
        (
          courseId,
          sectionName,
          courseName,
          courseLink
        )
      }

      val eventTuplesGroupedByCourseAndSectionIds = eventsTuples groupBy { t => t._1 + t._2 }

      val eventTuplesDeduped = eventTuplesGroupedByCourseAndSectionIds map { case (_, eventTuples) =>
        require(eventTuples.map(_._4).distinct.length == 1, {
          throw new IllegalStateException(s"We expect the same sections of a course to have the same URL. Instead got: $eventTuples")
        })
        val eventTuple = eventTuples(0)
        (
          eventTuple._1,
          eventTuple._2,
          eventTuple._3,
          eventTuple._4
        )
      }
      eventTuplesDeduped.groupBy(_._1).zipWithIndex.toSeq map { case (courseTuplesWithGroupBy, courseIndex) =>
        val courseTuples = courseTuplesWithGroupBy._2
        val contextMap = courseTuples.foldLeft(Map[String, String]()) { (acc, nextTuple) =>
          acc ++ Map(nextTuple._2 -> nextTuple._4)
        }
        val sampleTuple = courseTuples.head
        Course(
          SchoolId.Davis,
          departmentId = department.primaryKey,
          departmentSpecificCourseId = sampleTuple._1,
          name = sampleTuple._3,
          indexWithinDepartment = courseIndex,
          context = contextMap.pickle.value
        )
      }
    }
  }

  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = ???
}
