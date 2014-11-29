package fetch_managers

import com.typesafe.scalalogging.slf4j.LazyLogging
import course_refresh.{HTTPRequestFactory, HTTPManager, SchoolManager}
import model.{Department, Event, Section, Course}

import scala.concurrent.Future

class DavisCourseFetchManager(term: String) extends SchoolManager with LazyLogging {
  private val DavisRequestFactory: HTTPRequestFactory = new HTTPRequestFactory("https://registrar.ucdavis.edu/courses/search/index.cfm")

  override def fetchDepartments: Future[Seq[Department]] = HTTPManager.withHTTPManager(true) { httpManager =>
    httpManager.execute(DavisRequestFactory()) { page =>
      println(s"BOOM: $page")
      ???
    }
  }

  override def fetchCourses(department: Department): Future[Seq[Course]] = ???
  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = ???
}
