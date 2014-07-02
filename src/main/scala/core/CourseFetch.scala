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

object CourseFetch extends LazyLogging {
  def main(args: Array[String]) = {
    require(args.length == 1, {
      logger.error("Must pass in a single parameter to the course fetch process: the school id.")
    })
    val school: SchoolId = SchoolId(args(0).toInt)

    try {
      performCourseFetch(school)
    } finally {
      // Need to call shutdown to make sure dispatch is dead and the process can exit
      HTTPManager.shutdown()
    }
  }

  private def performCourseFetch(school: SchoolId) = {
    val fetchManager: CourseFetchManager = school match {
      case SchoolId.UCLA => UCLACourseFetchManager
    }
    logger.info(s"Starting the full course fetch for ${school.toString}")
    val allWorkFuture: Future[Unit] = fetchManager.fetchDepartments map { departments: Seq[Department] =>
      logger.info(s"Fetched the list of <${departments.length}> departments at ${school.toString}")
      val schoolSpecificIds = departments.map(_.schoolSpecificId)
      require(schoolSpecificIds.distinct.size == schoolSpecificIds.size, {
        logger.error(s"There are duplicate departments in school ${school.toString}")
      })
      val dbManager = new DBManager(DBConfig("localhost:3306/class_ninja", Some("root"), None))

      dbManager withSession { implicit session =>
        val currentTermCode = dbManager.schools.filter(_.schoolId === school.id).first.currentTermCode
        departments foreach { freshDepartment: Department =>
          val future = fetchManager.fetchCourses(currentTermCode, freshDepartment) map { courses: Seq[Course] =>
            logger.info(s"Fetched the list of <${courses.length}> courses at ${school.toString}'s ${freshDepartment.name}")
            val departmentSpecificCourseIds = courses.map(_.departmentSpecificCourseId)
            require(departmentSpecificCourseIds.distinct.size == departmentSpecificCourseIds.size, {
              logger.error(s"There exist duplicate courses in ${school.toString}'s <${freshDepartment.name}> department")
            })

            // Update the MySQL. Technically, it'd be nice to do this transactionally, however, slick doesn't support SELECT FOR UPDATE
            // and at this point, it's not really necessary for this update to be transactional. There are rarely going to be
            // multiple writers touching the same rows, and they're all trying to do the same thing, so it's OK if they
            // step over each other.
            val existingDepartments = dbManager.departments
              .filter(_.schoolId === school.id)
              .filter(_.schoolSpecificId === freshDepartment.schoolSpecificId)
              .list
            require(existingDepartments.length <= 1, {
              logger.error(s"There are duplicate departments in the db: <${school.toString}> <${freshDepartment.schoolSpecificId}>")
            })
            val refreshedDepartmentId = if (existingDepartments.length == 0) {
              val newDepId = (dbManager.departments returning dbManager.departments.map(_.departmentId)) += freshDepartment
              newDepId.toInt
            } else {
              val existingDepartmentId = existingDepartments(0).departmentId.get
              dbManager.departments
                .filter(_.departmentId === existingDepartmentId)
                .map(d => (d.schoolId, d.schoolSpecificId, d.name))
                .update(freshDepartment.schoolId, freshDepartment.schoolSpecificId, freshDepartment.name)
              existingDepartmentId
            }

            courses foreach { course: Course =>
              val existingCourses = dbManager.courses
                .filter(_.departmentId === refreshedDepartmentId)
                .filter(_.departmentSpecificCourseId === course.departmentSpecificCourseId)
                .list
              require(existingCourses.length <= 1, {
                logger.error(s"There are duplicate courses in the db: department<$refreshedDepartmentId> <${course.departmentSpecificCourseId}>")
              })
              val newCourseData = course.copy(departmentId = Option(refreshedDepartmentId))
              if (existingCourses.length == 0) {
                val newCourseId = (dbManager.courses returning dbManager.courses.map(_.courseId)) += newCourseData
                newCourseId.toInt
              } else {
                val existingCourseId = existingCourses(0).courseId.get
                dbManager.courses
                  .filter(_.courseId === existingCourseId)
                  .map(c => (c.schoolId, c.departmentId, c.departmentSpecificCourseId, c.name))
                  .update(course.schoolId, newCourseData.departmentId.get, newCourseData.departmentSpecificCourseId, newCourseData.name)
              }
            }
          }
          Await.result(future, Duration(5, TimeUnit.MINUTES))
        }
        Unit
      }
    }

    Await.result(allWorkFuture, Duration(1, TimeUnit.HOURS))
    logger.info(s"Finished the full course fetch for ${school.toString}")
  }
}

abstract class CourseFetchManager {
  def fetchDepartments: Future[Seq[Department]]
  def fetchCourses(term: String, department: Department): Future[Seq[Course]]
}

