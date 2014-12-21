package fetch_managers

import com.typesafe.scalalogging.slf4j.LazyLogging
import course_refresh.{HTTPRequest, HTTPManager, SchoolManager}
import model._

import scala.concurrent.Future
import scala.xml.{Node, NodeSeq}

class AlbanyCourseFetchManager(term: String) extends SchoolManager with LazyLogging {
  override def fetchDepartments: Future[Seq[Department]] = HTTPManager.withHTTPManager { httpManager =>
    httpManager.execute(HTTPRequest(
      root="http://www.albany.edu",
      path="registrar/schedule-of-classes-spring.php",
      method="GET",
      queryParams = Map[String, String](),
      body = None
    )){ nodeSeq: NodeSeq =>
      val departmentNodes: NodeSeq = nodeSeq \\ "select" filter (h=>((h \ "@name").toString) == "Department_or_Program")

      println(s"$departmentNodes")

      val test = (departmentNodes \\ "option") flatMap { node: Node =>
        val schoolSpecificIdOption = node.attribute("value")
        val name = node.text

        schoolSpecificIdOption flatMap { schoolSpecificId =>
          if (schoolSpecificId.head.text.length > 0) {
            Some(Department(SchoolId.Albany, schoolSpecificId.head.text, name))
          } else {
            None
          }
        }
      }
      println(s"$test")
      test
    }
  }

    // issue network request to fetch this page http://www.albany.edu/registrar/schedule-of-classes-spring.php
    // parse it
    // save to db



  override def fetchCourses(department: Department): Future[Seq[Course]] = ???

  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = ???
}
