package model

import model.SchoolId.SchoolId
import scala.slick.driver.MySQLDriver.simple._

case class Department(
  departmentId: Option[Int],
  schoolId: Int,
  schoolSpecificId: String,
  name: String
)


class Departments(tag: Tag) extends Table[Department](tag, "departments") {
  def departmentId = column[Option[Int]]("department_id", O.PrimaryKey, O.AutoInc)
  def schoolId = column[Int]("school_id")
  def schoolSpecificId = column[String]("school_specific_id")
  def name = column[String]("name")

  def schoolDerivedIndex = index("dep_school_derived_index", (schoolId, schoolSpecificId), unique = true)
  def school = foreignKey("dep_school_fk", schoolId, TableQuery[Schools])(_.schoolId)

  def * = (departmentId, schoolId, schoolSpecificId, name) <> ((Department.apply _).tupled, Department.unapply)
}

object Department {
  def create(schoolId: SchoolId, schoolSpecificId: String, name: String) = Department(None, schoolId.id, schoolSpecificId, name)
}
