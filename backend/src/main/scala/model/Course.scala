package model

import course_refresh.StringUtilities._
import model.SchoolId.SchoolId

import scala.slick.driver.MySQLDriver.simple._

case class Course(
  schoolId: SchoolId,
  departmentId: String,
  departmentSpecificCourseId: String,
  name: String,
  context: String
) {
  def primaryKey: String = {
    s"${departmentId}_$departmentSpecificCourseId".toSafeId
  }
}

class Courses(tag: Tag) extends Table[Course](tag, "courses") {
  def courseId = column[String]("course_id", O.PrimaryKey)
  def schoolId = column[Int]("school_id")
  def departmentId = column[String]("department_id")
  def departmentSpecificCourseId = column[String]("department_specific_course_id")
  def name = column[String]("name")
  def context = column[String]("context")

  def schoolDerivedIndex = index("crs_school_derived_index", (departmentId, departmentSpecificCourseId), unique = true)
  def school = foreignKey("crs_school_fk", schoolId, TableQuery[Schools])(_.schoolId)
  def department = foreignKey("crs_department_fk", departmentId, TableQuery[Departments])(_.departmentId)

  def * = (courseId, schoolId, departmentId, departmentSpecificCourseId, name, context) <> (createCourse, createTuple)

  private def createCourse(tuple: (String, Int, String, String, String, String)): Course = {
    Course(SchoolId(tuple._2), tuple._3, tuple._4, tuple._5, tuple._6)
  }

  private def createTuple(course: Course): Option[(String, Int, String, String, String, String)] = {
    Option((course.primaryKey, course.schoolId.id, course.departmentId, course.departmentSpecificCourseId, course.name, course.context))
  }

}
