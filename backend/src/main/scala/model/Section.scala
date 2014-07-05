package model

import model.SchoolId.SchoolId
import core.StringUtilities._
import scala.slick.driver.MySQLDriver.simple._

case class Section(
  sectionName: String,
  staffName: String,
  courseId: String,
  schoolId: SchoolId
) {
  def primaryKey: String = {
    s"${courseId}_$sectionName".toSafeId
  }
}

class Sections(tag: Tag) extends Table[Section](tag, "sections") {
  def sectionId = column[String]("section_id", O.PrimaryKey)
  def sectionName = column[String]("section_name")
  def staffName = column[String]("staff_name")
  def courseId = column[String]("course_id")
  def schoolId = column[Int]("school_id")

  def school = foreignKey("sec_school_fk", schoolId, TableQuery[Schools])(_.schoolId)
  def course = foreignKey("sec_course_fk", courseId, TableQuery[Courses])(_.courseId)

  def * = (sectionId, sectionName, staffName, courseId, schoolId) <> (createSection, createTuple)

  private def createSection(tuple: (String, String, String, String, Int)): Section = {
    Section(tuple._2, tuple._3, tuple._4, SchoolId(tuple._5))
  }

  private def createTuple(section: Section): Option[(String, String, String, String, Int)] = {
    Option((section.primaryKey, section.sectionName, section.staffName, section.courseId, section.schoolId.id))
  }
}
