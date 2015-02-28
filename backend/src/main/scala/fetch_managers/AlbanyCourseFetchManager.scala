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
      val inputNodes: NodeSeq = nodeSeq \\ "input"
      val testInputNodes = (inputNodes ) map { node: Node =>
        val value = node.attribute("value").toString()
        val name = node.attribute("name").toString()
        (name, value)
      }

      println(s"$testInputNodes")
      val departmentNodes: NodeSeq = nodeSeq \\ "select" filter (h=>((h \ "@name").toString) == "Department_or_Program")
      val test = (departmentNodes \\ "option") flatMap { node: Node =>
        val schoolSpecificIdOption = node.attribute("value")
        val name = node.text

        schoolSpecificIdOption flatMap { schoolSpecificId =>
          val headText = schoolSpecificId.head.text
          if (headText.length > 0) {
            val schoolSpecificId : String = headText + "__" + name.replaceAll(" ","_")
            Some(Department(SchoolId.Albany, schoolSpecificId, name))
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


//  Level: Undergraduate
//  College or School: College of Computing & Information
//  Department or Program: Computer Science
//    Class Number: 7116
//  Grading: A-E
//  Course Info: ICSI 105 Computing and Information
//  Meeting Info: TTH 10:15_AM-11:35_AM HU0024 Magnus,Cristyn E B
//  Comments:
//    Credit Range: 3.0- 3.0
//  Component is blank if lecture:
//    Topic if applicable:
//    Seats remaining as of last update: 4
//  Session: 1
//  IT Commons Course: N
//  Fully Online Course: N
//  General Education Course: NONE
//  Honors College Course: N
//  Writing Intensive Course: N
//  Oral Discourse Course: N
//  Information Literacy Course: N
//  Special Restriction: Seats Remaining for: Spring 2015 Transfer - 4, Seats Remaining for any students: 0

//  Course(SchoolId.UCLA, department.primaryKey, departmentSpecificCourseId, courseName, index, httpManager.reqFromHTTPRequest(request).url)
  override def fetchCourses(department: Department): Future[Seq[Course]] = HTTPManager.withHTTPManager {
  val schoolSpecificDepartmentCode = department.schoolSpecificId.split("__")(0)
  val albanyFormDataForDepartment = albanyFormData + ("Department_or_Program" -> schoolSpecificDepartmentCode.toString())
  println(albanyFormDataForDepartment)

  println(department.name)
  httpManager =>
    httpManager.execute(HTTPRequest(
//      root = "http://www.albany.edu",
//      path = "cgi-bin/general-search/search.pl",
      root = "http://requestb.in",
      path = "1jsd6tr1",
      method = "POST",
      queryParams = Map[String, String](),
      body = Some(albanyFormDataForDepartment)
    )) { nodeSeq: NodeSeq =>
      val nodes: NodeSeq = nodeSeq
      println(s"$nodes")
      List(Course(SchoolId.Albany, department.primaryKey, "departmentSpecificCourseId", "courseName", 0, ""))
      //      Course(SchoolId.UCLA, department.primaryKey, departmentSpecificCourseId, courseName, index, httpManager.reqFromHTTPRequest(request).url)
    }

  }
// must have this in correct order: USER=0007&DELIMITER=%5Ct&Level=&College_or_School=&Department_or_Program=accounting



  private val albanyFormData = Map(
    "USER" -> "0007",
    "DELIMITER" -> "\\t",
    "Level" -> "",
    "College_or_School" -> "",
    "Department_or_Program" -> "",
    "Course_Subject" -> "",
    "Course_Number" -> "",
    "Class_Number" -> "",
    "Course_Title" -> "",
    "Days" -> "",
    "Instructor" -> "",
    "Grading" -> "",
    "Course_Info" -> "",
    "Meeting_Info" -> "",
    "Comments" -> "",
    "Credit_Range" -> "",
    "Component_is_blank_if_lecture" -> "",
    "Topic_if_applicable" -> "",
    "Seats_remaining_as_of_last_update" -> "",
    "Session" -> "",
    "IT_Commons_Course" -> "",
    "Fully_Online_Course" -> "",
    "General_Education_Course" -> "",
    "Honors_College_Course" -> "",
    "Writing_Intensive_Course" -> "",
    "Oral_Discourse_Course" -> "",
    "Information_Literacy_Course" -> "",
    "Special_Restriction" -> ""
  );

  //    "SUBST_STR" -> "G:Graduate",
  //    "SUBST_STR" -> "U:Undergraduate",
  //    "SUBST_STR" -> "L:Lab",
  //    "SUBST_STR" -> "D:Discussion",
  //    "SUBST_STR" -> "S:Seminar",
  //    "SUBST_STR" -> "I:Independent Study",
  //    "SUBST_STR" -> "GRD:A-E",
  //    "SUBST_STR" -> "SUS:Satisfactory/Unsatisfactory",
  //    "SUBST_STR" -> "GLU:Load Credit or Unsatisfactory",
  //    "SUBST_STR" -> "GRU:Research Credit or Unsatisfactory",


  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = ???
}

