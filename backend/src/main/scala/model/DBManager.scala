package model

import scala.slick.driver.MySQLDriver.simple._
import scala.slick.jdbc.meta.MTable

class DBManager(dbConfig: DBConfig) {

  private val db = Database.forURL(
    s"jdbc:mysql://${dbConfig.mySqlEndpoint}",
    user = dbConfig.user.getOrElse(""),
    password = dbConfig.password.getOrElse(""),
    driver = "com.mysql.jdbc.Driver"
  )
  val schools = TableQuery[Schools]
  val departments = TableQuery[Departments]
  val courses = TableQuery[Courses]
  initialize()

  private def initialize() = {
    createIfNeeded(schools)
    createIfNeeded(departments)
    createIfNeeded(courses)
  }

  def createIfNeeded[T <: Table[_]](table: TableQuery[T]) = db withSession { implicit session: Session =>
    if (MTable.getTables(table.baseTableRow.tableName).list.isEmpty) {
      table.ddl.create
    }
  }

  def withSession(work: Session => Unit) = db withSession work
}

case class DBConfig(mySqlEndpoint: String, user: Option[String], password: Option[String])
