package core

import java.util.concurrent.TimeUnit

import model.SchoolId.SchoolId
import model._
import ucla.UCLACourseFetchManager
import scala.slick.driver.MySQLDriver.simple._
import scala.concurrent.duration.Duration
import scala.concurrent.{Await, ExecutionContext, Future}
import ExecutionContext.Implicits.global
import com.typesafe.scalalogging.slf4j.LazyLogging
import com.typesafe.config.ConfigFactory
import java.io.File

object CourseFetch extends LazyLogging {
  def main(args: Array[String]) = {
    require(args.length == 1, {
      logger.error("Must pass in a single parameter to the course fetch process: the school id.")
    })
    val school: SchoolId = SchoolId(args(0).toInt)

    val courseFetchConf = {
      val file = new File("environment.conf")
      val confFromFile = ConfigFactory.parseFile(file)
      if (confFromFile.isEmpty) {
        ConfigFactory.load("environment").getConfig("course-fetch")
      } else {
        confFromFile.getConfig("course-fetch")
      }
    }
    logger.info(s"Going to use conf: $courseFetchConf")

    try {
      val databaseConf = courseFetchConf.getConfig("database")
      implicit val dbManager = new DBManager(DBConfig(databaseConf))
      dbManager withSession { implicit session =>
        performCourseFetch(school)
      }
    } finally {
      // Need to call shutdown to make sure dispatch is dead and the process can exit
      HTTPManager.shutdown()
    }
  }

  private def performCourseFetch(school: SchoolId)(implicit dbManager: DBManager, session: Session) = {
    val fetchManager: CourseFetchManager = school match {
      case SchoolId.UCLA => UCLACourseFetchManager
    }
    logger.info(s"Starting the full course fetch for ${school.toString}")
    val allWorkFuture: Future[Any] = fetchManager.fetchDepartments flatMap { departments: Seq[Department] =>
      logger.info(s"Fetched the list of <${departments.length}> departments at ${school.toString}")
      val schoolSpecificIds = departments.map(_.schoolSpecificId)
      require(schoolSpecificIds.distinct.size == schoolSpecificIds.size, {
        logger.error(s"There are duplicate departments in school ${school.toString}")
      })

      val currentTermCode = dbManager.schools.filter(_.schoolId === school.id).first.currentTermCode

      val futures = departments map { freshDepartment: Department =>
        fetchManager.fetchCourses(currentTermCode, freshDepartment) flatMap { courses: Seq[Course] =>
          val departmentSpecificCourseIds = courses.map(_.departmentSpecificCourseId)
          require(departmentSpecificCourseIds.distinct.size == departmentSpecificCourseIds.size, {
            logger.error(s"There exist duplicate courses in ${school.toString}'s <${freshDepartment.name}> department")
          })

          fetchManager.fetchEvents(courses) map { events: Seq[(Section, Seq[Event])] =>

            // Update the MySQL. Technically, might be nice to do this transactionally, however at this point, it's not
            // really necessary for this update to be transactional. There are rarely going to be multiple writers
            // touching the same rows, and they're all trying to do the same thing, so it's OK if they
            // step over each other.
            dbManager.departments.insertOrUpdate(freshDepartment)
            courses foreach { course: Course =>
              dbManager.courses.insertOrUpdate(course)
            }
            events foreach { case (section: Section, sectionsEvents: Seq[Event]) =>
              dbManager.sections.insertOrUpdate(section)
            }
            logger.info(s"Done updating <${courses.length}> courses at ${school.toString}'s ${freshDepartment.name}")
          }
        }
      }
      Future sequence futures
    }

    Await.result(allWorkFuture, Duration(1, TimeUnit.HOURS))
    logger.info(s"Finished the full course fetch for ${school.toString}")
  }
}

abstract class CourseFetchManager {
  def fetchDepartments: Future[Seq[Department]]
  def fetchCourses(term: String, department: Department): Future[Seq[Course]]
  def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]]
}

