package ucla

import core.{HTTPRequestFactory, CourseFetchManager, HTTPManager}
import model.{Course, Department, SchoolId}
import core.NodeSeqUtilities._
import scala.concurrent.Future
import scala.xml.{Node, NodeSeq}


object UCLACourseFetchManager extends CourseFetchManager {
  private val UCLARequestFactory: HTTPRequestFactory = new HTTPRequestFactory("http://www.registrar.ucla.edu/schedule")

  override def fetchDepartments: Future[Seq[Department]] = {
    HTTPManager.execute(UCLARequestFactory("/schedulehome.aspx")) { nodeSeq: NodeSeq =>
      val departmentNodes: NodeSeq = (nodeSeq \\ "select").filterByAttribute("id", "ctl00_BodyContentPlaceHolder_SOCmain_lstSubjectArea") \\ "option"
      require(departmentNodes.length > 0, "Wasn't able to find the list of departments")
      departmentNodes map { node: Node =>
        val schoolSpecificId = node.attribute("value").get.text
        val name = node.text
        Department.create(SchoolId.UCLA, schoolSpecificId, name)
      }
    }
  }

  override def fetchCourses(term: String, department: Department): Future[Seq[Course]] = {
    val coursesRequest = UCLARequestFactory("/crsredir.aspx", Map("termsel" -> term, "subareasel" -> department.schoolSpecificId))
    HTTPManager.execute(coursesRequest) { nodeSeq =>
      val courseNodes: NodeSeq = (nodeSeq \\ "select").filterByAttribute("id", "ctl00_BodyContentPlaceHolder_crsredir1_lstCourseNormal") \\ "option"
      courseNodes map { node: Node =>
        val departmentSpecificCourseId :: courseName :: _ = node.text.split(" - ", 2).toList
        Course.create(SchoolId.UCLA, departmentSpecificCourseId, courseName)
      }
    }
  }
}
