package fetch_managers

import com.typesafe.scalalogging.slf4j.LazyLogging
import course_refresh.{HTTPRequestFactory, HTTPManager, SchoolManager}
import model._
import course_refresh.NodeSeqUtilities._

import scala.concurrent.Future

class DavisCourseFetchManager(term: String) extends SchoolManager with LazyLogging {
  private val DavisRequestFactory: HTTPRequestFactory = new HTTPRequestFactory("https://registrar.ucdavis.edu/courses/search/index.cfm")

  override def fetchDepartments: Future[Seq[Department]] = HTTPManager.withHTTPManager(true) { httpManager =>
    httpManager.execute(DavisRequestFactory()) { page =>
      val subjectSelect = (page \\ "select").filterByLiteralAttribute("name", "subject")
      (subjectSelect \\ "option") flatMap { optionNode =>
        val optionalDepartmentCode = optionNode.attribute("value").map(_.head.text)
        optionalDepartmentCode.fold {
          logger.warn("Encountered a department option without a value attribute.")
          None: Option[Department]
        } { departmentCode =>
          if (departmentCode.length == 3) {
            val departmentName = optionNode.text.replaceFirst(s" \\(${departmentCode}\\)$$", "")
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

  override def fetchCourses(department: Department): Future[Seq[Course]] = ???
  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = ???
}
