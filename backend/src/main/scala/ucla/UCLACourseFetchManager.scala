package ucla

import core.{HTTPRequestFactory, CourseFetchManager, HTTPManager}
import model._
import core.NodeSeqUtilities._
import scala.concurrent.Future
import scala.xml.{Node, NodeSeq}
import scala.concurrent.ExecutionContext.Implicits.global
import model.Course
import model.Department
import model.Section


object UCLACourseFetchManager extends CourseFetchManager {
  private val UCLARequestFactory: HTTPRequestFactory = new HTTPRequestFactory("http://www.registrar.ucla.edu/schedule")

  override def fetchDepartments: Future[Seq[Department]] = {
    HTTPManager.execute(UCLARequestFactory("/schedulehome.aspx")) { nodeSeq: NodeSeq =>
      val departmentNodes: NodeSeq = (nodeSeq \\ "select").filterByLiteralAttribute("id", "ctl00_BodyContentPlaceHolder_SOCmain_lstSubjectArea") \\ "option"
      require(departmentNodes.length > 0, "Wasn't able to find the list of departments")
      departmentNodes map { node: Node =>
        val schoolSpecificId = node.attribute("value").get.text
        val name = node.text
        Department(SchoolId.UCLA, schoolSpecificId, name)
      }
    }
  }

  override def fetchCourses(term: String, department: Department): Future[Seq[Course]] = {
    val coursesRequest = UCLARequestFactory("/crsredir.aspx", Map("termsel" -> term, "subareasel" -> department.schoolSpecificId))
    HTTPManager.execute(coursesRequest) { nodeSeq =>
      val courseNodes: NodeSeq = (nodeSeq \\ "select").filterByLiteralAttribute("id", "ctl00_BodyContentPlaceHolder_crsredir1_lstCourseNormal") \\ "option"
      courseNodes map { node: Node =>
        val departmentSpecificCourseId :: courseName :: _ = node.text.split(" - ", 2).toList
        val request = UCLARequestFactory(
          path = "/detselect.aspx",
          queryParams = Map("termsel" -> term, "subareasel" -> department.schoolSpecificId, "idxcrs" -> node.attribute("value").get.text)
        )
        Course(SchoolId.UCLA, department.primaryKey, departmentSpecificCourseId, courseName, HTTPManager.reqFromHTTPRequest(request).url)
      }
    }
  }

  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = {
    val sectionFutures: Seq[Future[Seq[(Section, Seq[Event])]]] = courses map { course: Course =>
      HTTPManager.get(course.context) { nodeSeq: NodeSeq =>
        val sectionNodes: NodeSeq = (nodeSeq \\ "table").filterByAttributePrefix("id", "dgdLectureHeader")
        val sectionNameRegex = "^ctl00_BodyContentPlaceHolder_detselect_dgdLectureHeader.*_ctl02_lblGenericMessage$"
        val staffRegex = "^ctl00_BodyContentPlaceHolder_detselect_dgdLectureHeader.*_ctl02_lblGenericMessage2$"
        sectionNodes map { sectionNode: Node =>
          val sectionNodes: NodeSeq = sectionNode \\ "span"
          val sectionName: String = sectionNodes.filterByAttribute("id", _.matches(sectionNameRegex))(0).text
          val staff: String = sectionNodes.filterByAttribute("id", _.matches(staffRegex)).text.
            trim().
            replaceAllLiterally("\u00a0", "").
            replaceAll(" {2,}", "")
          val section = Section(
            sectionName,
            staff,
            course.primaryKey,
            course.schoolId
          )
          (section, Seq[Event]())
        }
      }
    }
    (Future sequence sectionFutures).map(_.flatten)
  }
}
