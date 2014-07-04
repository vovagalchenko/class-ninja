package model

import scala.slick.driver.MySQLDriver.simple._
import model.SchoolId.SchoolId

object School {
  def create(schoolId: SchoolId, schoolName: String, currentTermCode: String, currentTermName: String) = {
    School(schoolId.id, schoolName, currentTermCode, currentTermName)
  }
}

case class School(
  schoolId: Int,
  schoolName: String,
  currentTermCode: String,
  currentTermName: String
)

class Schools(tag: Tag) extends Table[School](tag, "schools") {
  def schoolId = column[Int]("school_id", O.PrimaryKey)
  def schoolName = column[String]("school_name")
  def currentTermCode = column[String]("current_term_code")
  def currentTermName = column[String]("current_term_name")

  def * = (schoolId, schoolName, currentTermCode, currentTermName) <> ((School.apply _).tupled, School.unapply)
}
