package ucla

import core.{HTTPRequestFactory, CourseFetchManager, HTTPManager}
import model.{Course, Department, SchoolId}

import scala.concurrent.Future
import scala.xml.{Node, NodeSeq}


object UCLACourseFetchManager extends CourseFetchManager {
  private val UCLARequestFactory: HTTPRequestFactory = new HTTPRequestFactory("http://www.registrar.ucla.edu/schedule")

  override def fetchDepartments: Future[Seq[(String, Department)]] = {
    HTTPManager.execute(UCLARequestFactory("/schedulehome.aspx")) { nodeSeq: NodeSeq =>
      val departmentNodes: NodeSeq = (nodeSeq \\ "select").filter { node: Node =>
        node.attribute("id") match {
          case Some(id) => id.text == "ctl00_BodyContentPlaceHolder_SOCmain_lstSubjectArea"
          case None => false
        }
      } \\ "option"
      require(departmentNodes.length > 0, "Wasn't able to find the list of departments")
      departmentNodes map { node: Node =>
        val schoolSpecificId = node.attribute("value").get.text
        val name = node.text
        (schoolSpecificId, Department.create(SchoolId.UCLA, schoolSpecificId, name))
      }
    }
  }

  override def fetchCourses(term: String, department: Department): Future[Seq[(String, Course)]] = {
    val coursesRequest = UCLARequestFactory("/crsredir.aspx", Map("termsel" -> term, "subareasel" -> department.schoolSpecificId))
    println(coursesRequest)
    HTTPManager.execute(coursesRequest) { nodeSeq =>
      println("DONE")
      val tuple = ("banana", Course.create(SchoolId.UCLA, 0, "holy fuck", "hello"))
      Seq(tuple)
    }
  }
}
