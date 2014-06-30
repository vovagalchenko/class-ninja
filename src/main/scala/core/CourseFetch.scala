package core

import java.util.concurrent.TimeUnit

import model.SchoolId.SchoolId
import model._
import ucla.UCLACourseFetchManager
import scala.slick.driver.MySQLDriver.simple._

import scala.concurrent.duration.Duration
import scala.concurrent.{Await, ExecutionContext, Future}
import ExecutionContext.Implicits.global


object CourseFetch {
  def main(args: Array[String]) = {
    require(args.length == 1, "Must pass in a single parameter to the course fetch process: the school id.")
    val school: SchoolId = SchoolId(args(0).toInt)
    val fetchManager: CourseFetchManager = school match {
      case SchoolId.UCLA => UCLACourseFetchManager
    }

    val futureFreshDepartments: Future[Unit] = fetchManager.fetchDepartments map { departments: Seq[(String, Department)] =>
      val schoolSpecificIds = departments.map(_._1)
      require(schoolSpecificIds.distinct.size == schoolSpecificIds.size, "There should never be any duplicate school specific ids for a given school")
      val dbManager = new DBManager(DBConfig("localhost:3306/class_ninja", Some("root"), None))

      dbManager withSession { implicit session =>
        val currentTermCode = dbManager.schools.filter(_.schoolId === school.id).first.currentTermCode
        departments map { case (schoolSpecificId, freshDepartment) =>

          fetchManager.fetchCourses(currentTermCode, freshDepartment)

          // Update the MySQL
          session withTransaction {
            val numRowsUpdated = dbManager.departments
              .filter(_.schoolId === school.id)
              .filter(_.schoolSpecificId === freshDepartment.schoolSpecificId)
              .map(d => (d.schoolId, d.schoolSpecificId, d.name))
              .update(freshDepartment.schoolId, freshDepartment.schoolSpecificId, freshDepartment.name)
            require(numRowsUpdated <= 1, "Can't have more than one row given a school and a school specific id in the database")
            if (numRowsUpdated == 0) {
              dbManager.departments += freshDepartment
            }
          }
        }
        Unit
      }
    }

    Await.result(futureFreshDepartments, Duration(100, TimeUnit.SECONDS))
  }
}

abstract class CourseFetchManager {
  def fetchDepartments: Future[Seq[(String, Department)]]
  def fetchCourses(term: String, department: Department): Future[Seq[(String, Course)]]
}

