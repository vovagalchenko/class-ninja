package fetch_managers

import com.typesafe.scalalogging.slf4j.LazyLogging
import course_refresh.{HTTPRequest, HTTPManager, SchoolManager}
import model._

import scala.concurrent.Future
import scala.xml.{Node, NodeSeq}
import scala.concurrent.ExecutionContext.Implicits.global

class AlbanyCourseFetchManager(term: String) extends SchoolManager with LazyLogging {
  lazy val allDepartments: Future[NodeSeq] = {
    HTTPManager.withHTTPManager { httpManager =>
      httpManager.execute(HTTPRequest(
        root = "http://www.albany.edu",
        path = "registrar/schedule-of-classes-spring.php",
        method = "GET",
        queryParams = Map[String, String](),
        body = None
      )) { nodeSeq: NodeSeq =>
        nodeSeq
      }
    }
  }

  lazy val allCoursesAndEvents: Future[String] = {
    HTTPManager.withHTTPManager { httpManager =>
        httpManager.execute(HTTPRequest(
          root = "http://www.albany.edu",
          path = "cgi-bin/general-search/search.pl",
          method = "POST",
          queryParams = Map[String, String](),
          body = Some(albanyFormData)
        )) { nodeSeq: NodeSeq =>
          nodeSeq.toString()
        }
      }
  }


  override def fetchDepartments: Future[Seq[Department]] = allDepartments map { nodeSeq: NodeSeq =>
      val departmentNodes: NodeSeq = nodeSeq \\ "select" filter (h=>((h \ "@name").toString) == "Department_or_Program")
      val test = (departmentNodes \\ "option") flatMap { node: Node =>
        val schoolSpecificIdOption = node.attribute("value")
        val name = node.text

        schoolSpecificIdOption flatMap { schoolSpecificId =>
          val headText = schoolSpecificId.head.text
          if (headText.length > 0) {
            val schoolSpecificId : String = name.replaceAll(" ","_")
            Some(Department(SchoolId.Albany, schoolSpecificId, name))
          } else {
            None
          }
        }
      }
      test
    }

  override def fetchCourses(department: Department): Future[Seq[Course]] = allCoursesAndEvents map { allCoursesAndEventsString : String =>
    val departmentName = department.name

    val courseInfoString =
      """Department or Program: <b>""" +
        s"$departmentName"+"""<\/b><br clear="none"\/>\nClass Number: <b>.*?<\/b><br clear="none"\/>\nGrading: <b>.*?<\/b><br clear="none"\/>\nCourse Info: <b>(.*?)</b>"""

    val courseInfoRegex = courseInfoString.r
    val courseInfoIterator = for (m <- courseInfoRegex findAllMatchIn allCoursesAndEventsString) yield  (m.group(1))
    val courseInfoList = courseInfoIterator.toList.distinct

    courseInfoList.zipWithIndex.map { case (courseName: String, indexWithinDepartment: Int)  =>
      val courseNameWords = courseName split " "
      val courseNumericId =  (courseNameWords)(2)
      val deptShortForm = (courseNameWords)(0)
      val departmentSpecificCourseId = "ALBANY_" + s"$deptShortForm" + "_" + courseNumericId
      Course(SchoolId.Albany, department.primaryKey, departmentSpecificCourseId, courseName, indexWithinDepartment, "")
    }.toSeq
  }


  private val daysOfWeekMap = Map(
    "Mo" -> "M",
    "Tu"  -> "T",
    "We"  -> "W",
    "Th"  -> "R",
    "Fr"  -> "F",
    "Sa" -> "S"
  )

// TTH 08:45_AM-10:05_AM LC0007 Lester,Marisa Beth
// F 01:40_PM-02:35_PM BBB006
// [{"weekdays" : "MTWRF", "timeInterval" : "1:00PM - 4:45PM", "location" : "Clark Building 302"}]

  override def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]] = allCoursesAndEvents map { allCoursesAndEventsString : String =>

    val t = courses flatMap { course =>

      val courseName = course.name

      val eventInfoString =
        """Class Number: <b>(.*?)<\/b><br clear="none"\/>\n""" +
          """Grading: <b>.*?<\/b><br clear="none"\/>\n""" +
          """Course Info: <b>""" + s"$courseName" + """</b><br clear="none"\/>\n""" +
          """Meeting Info: <b>(.*?)<\/b><br clear="none"\/>\n""" +
          """Comments: <b>.*?<\/b><br clear="none"\/>\n""" +
          """Credit Range: <b>.*?<\/b><br clear="none"\/>\n""" +
          """Component is blank if lecture: <b>(.*?)<\/b><br clear="none"\/>\n""" +
          """Topic if applicable: <b>.*?<\/b><br clear="none"\/>\n""" +
          """Seats remaining as of last update: <b>(.*?)<\/b><br clear="none"\/>\n"""


      val eventInfoRegex = eventInfoString.r

      val eventsInfoIterator = for (m <- eventInfoRegex findAllMatchIn allCoursesAndEventsString) yield ((m.group(1), m.group(2), m.group(3), m.group(4)))

      val sectionAndEvent = eventsInfoIterator.zipWithIndex.map {
        case ((classNumber : String, meetingInfo : String, eventType : String, seatsRemaining : String), schoolSpecificEventId : Int) =>
          val sectionType = if (eventType.trim() == "") "LEC" else eventType.trim()

          val timesAndLocations = Seq(Spacetime("F", "1:00PM - 4:45PM", "BBB006"))
          val enrollmentCap = 0
          val status = "Open"

          val sectionName = course.departmentSpecificCourseId + "_" + sectionType +"_" + classNumber.trim()
          val staffName = "staff name here"
          val section = Section(sectionName, staffName, course.primaryKey, SchoolId.Albany)
          val event = Event(Some("ALBANY_"+classNumber), sectionType, timesAndLocations,
            0, enrollmentCap, 0, 0, status, section.primaryKey, SchoolId.Albany)


//          println(classNumber)
//          println(meetingInfo)
//          println(sectionType)
//          println(seatsRemaining)

          (section, event :: Nil)
      }

      sectionAndEvent.toSeq
    }

    t
  }


//  Level: <b>Undergraduate</b><br clear="none"/>
//  College or School: <b>College of Arts and Sciences</b><br clear="none"/>
//  Department or Program: <b>Women's, Gender &amp; Sexuality Studies</b><br clear="none"/>
//  Class Number: <b> 3944</b><br clear="none"/>
//  Grading: <b>A-E</b><br clear="none"/>
//  Course Info: <b>AWSS  495 Honors Project</b><br clear="none"/>
//  Meeting Info: <b>  12:00_PM-12:00_PM ARR Hobson,Janell C</b><br clear="none"/>
//  Comments: <b> Permission of Instructor</b><br clear="none"/>
//  Component is blank if lecture: <b> 3.0- 3.0</b><br clear="none"/>
//  Credit Range: <b> </b><br clear="none"/>
//  Topic if applicable: <b> </b><br clear="none"/>
//  Seats remaining as of last update: <b>5</b><br clear="none"/>
//  Session: <b>1</b><br clear="none"/>
//  IT Commons Course: <b>N</b><br clear="none"/>
//  Fully Online Course: <b>N</b><br clear="none"/>
//  General Education Course: <b>NONE</b><br clear="none"/>
//  Honors College Course: <b>N</b><br clear="none"/>
//  Writing Intensive Course: <b>N</b><br clear="none"/>
//  Oral Discourse Course: <b>N</b><br clear="none"/>
//  Information Literacy Course: <b>N</b><br clear="none"/>
//  Special Restriction: <b>None</b><br clear="none"/>


  //      Class Number: 2922
  //      Grading: A-E
  //      Course Info: BACC 222 Cost Acc Sys
  //      Meeting Info: TTH 10:15_AM-11:35_AM LC0007 Lester,Marisa Beth
  //      Comments: Students Registering For This Section Must FIRST Register For One Disc From: 3925-3928, 3930, 3932, 3933. Students who do not advance register for this course cannot be given consideration for a permission number if the course closes.
  //      Credit Range: 3.0- 3.0
  //      Component is blank if lecture:
  //      Topic if applicable:
  //      Seats remaining as of last update: 11


  //
  //    Section(
  //      sectionName,
  //      staff,
  //      course.primaryKey,
  //      course.schoolId
  //    )
  //
  //    val event = Event(
  //      Some(schoolSpecificEventId),
  //      sectionName,
  //      timesAndLocations,
  //      numEnrolled,
  //      enrollmentCap,
  //      numWaitlisted,
  //      waitListCap,
  //      status,
  //      section.primaryKey,
  //      SchoolId.SJSU
  //    )

  private val albanyFormData = Seq(
    ("USER", "0007"),
    ("DELIMITER", "\\t"),
    ("SUBST_STR", "G:Graduate"),
    ("SUBST_STR", "U:Undergraduate"),
    ("SUBST_STR", "L:Lab"),
    ("SUBST_STR", "D:Discussion"),
    ("SUBST_STR", "S:Seminar"),
    ("SUBST_STR", "I:Independent Study"),
    ("SUBST_STR", "GRD:A-E"),
    ("SUBST_STR", "SUS:Satisfactory/Unsatisfactory"),
    ("SUBST_STR", "GLU:Load Credit or Unsatisfactory"),
    ("SUBST_STR", "GRU:Research Credit or Unsatisfactory"),
    ("HEADING_FONT_FACE", "Arial"),
    ("HEADING_FONT_SIZE", "3"),
    ("HEADING_FONT_COLOR", "black"),
    ("RESULTS_PAGE_TITLE", ""),
    ("RESULTS_PAGE_BGCOLOR", "#F0F0F0"),
    ("RESULTS_PAGE_HEADING", ""),
    ("RESULTS_PAGE_FONT_FACE", "Arial"),
    ("RESULTS_PAGE_FONT_SIZE", "2"),
    ("RESULTS_PAGE_FONT_COLOR", "black"),
    ("NO_MATCHES_MESSAGE", "Sorry, no courses were found that match your criteria."),
    ("NO_PRINT", "3"),
    ("NO_PRINT", "4"),
    ("NO_PRINT", "6"),
    ("NO_PRINT", "7"),
    ("NO_PRINT", "8"),
    ("GREATER_THAN_EQ", "26"),
    ("NO_PRINT", "26"),
    ("Level", ""),
    ("College_or_School", ""),
    ("Department_or_Program", ""),
    ("Course_Subject", ""),
    ("Course_Number", ""),
    ("Class_Number", ""),
    ("Course_Title", ""),
    ("Days", ""),
    ("Instructor", ""),
    ("Grading", ""),
    ("Course_Info", ""),
    ("Meeting_Info", ""),
    ("Comments", ""),
    ("Credit_Range", ""),
    ("Component is blank if lecture", ""),
    ("Topic_if_applicable", ""),
    ("Seats_remaining_as_of_last_update", ""),
    ("Session", ""),
    ("IT_Commons_Course", ""),
    ("Fully_Online_Course", ""),
    ("General_Education_Course", ""),
    ("Honors_College_Course", ""),
    ("Writing_Intensive_Course", ""),
    ("Oral_Discourse_Course", ""),
    ("Information_Literacy_Course", ""),
    ("Special_Restriction", "")
  );


}

