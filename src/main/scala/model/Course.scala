package model

import model.SchoolId.SchoolId

import scala.slick.driver.MySQLDriver.simple._

case class Course(
  courseId: Option[Int],
  schoolId: Int,
  departmentId: Option[Int],
  departmentSpecificCourseId: String,
  name: String)

class Courses(tag: Tag) extends Table[Course](tag, "courses") {
  def courseId = column[Int]("course_id", O.PrimaryKey, O.AutoInc)
  def schoolId = column[Int]("school_id")
  def departmentId = column[Int]("department_id")
  def departmentSpecificCourseId = column[String]("department_specific_course_id")
  def name = column[String]("name")

  def schoolDerivedIndex = index("crs_school_derived_index", (departmentId, departmentSpecificCourseId), unique = true)
  def school = foreignKey("crs_school_fk", schoolId, TableQuery[Schools])(_.schoolId)

  def * = (courseId.?, schoolId, departmentId.?, departmentSpecificCourseId, name) <> ((Course.apply _).tupled, Course.unapply)
}

object Course {
  def create(schoolId: SchoolId, departmentSpecificCourseId: String, name: String): Course = {
    Course(None, schoolId.id, None, departmentSpecificCourseId, name)
  }
}
