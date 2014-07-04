package model

import model.SchoolId.SchoolId
import core.StringUtilities._
import scala.slick.driver.MySQLDriver.simple._

case class Department(
  schoolId: SchoolId,
  schoolSpecificId: String,
  name: String
) {
  def primaryKey: String = {
    s"${schoolId}_$schoolSpecificId".toSafeId
  }
}

class Departments(tag: Tag) extends Table[Department](tag, "departments") {
  def departmentId = column[String]("department_id", O.PrimaryKey)
  def schoolId = column[Int]("school_id")
  def schoolSpecificId = column[String]("school_specific_id")
  def name = column[String]("name")

  def schoolDerivedIndex = index("dep_school_derived_index", (schoolId, schoolSpecificId), unique = true)
  def school = foreignKey("dep_school_fk", schoolId, TableQuery[Schools])(_.schoolId)

  def * = (departmentId, schoolId, schoolSpecificId, name) <> (createDepartment, createTuple)

  private def createDepartment(tuple: (String, Int, String, String)): Department = {
    Department(SchoolId(tuple._2), tuple._3, tuple._4)
  }

  private def createTuple(department: Department): Option[(String, Int, String, String)] = {
    Option((department.primaryKey, department.schoolId.id, department.schoolSpecificId, department.name))
  }
}
