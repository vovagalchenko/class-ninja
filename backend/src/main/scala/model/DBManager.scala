package model

import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.DBConfig

import scala.slick.driver.MySQLDriver.simple._
import scala.slick.jdbc.meta.MTable

class DBManager(dbConfig: DBConfig) extends LazyLogging {

  private val db = Database.forURL(
    s"jdbc:mysql://${dbConfig.mySqlEndpoint}",
    user = dbConfig.user.getOrElse(""),
    password = dbConfig.password.getOrElse(""),
    driver = "com.mysql.jdbc.Driver"
  )
  val schools = TableQuery[Schools]
  val departments = TableQuery[Departments]
  val courses = TableQuery[Courses]
  val sections = TableQuery[Sections]
  val events = TableQuery[Events]
  val users = TableQuery[Users]
  val targets = TableQuery[Targets]
  initialize()

  private def initialize() = {
    createIfNeeded(schools)
    createIfNeeded(departments)
    createIfNeeded(courses)
    createIfNeeded(sections)
    createIfNeeded(events)
    createIfNeeded(users)
    createIfNeeded(targets)
  }

  def createIfNeeded[T <: Table[_]](table: TableQuery[T]) = db withSession { implicit session: Session =>
    if (MTable.getTables(table.baseTableRow.tableName).list.isEmpty) {
      logger.info(s"Creating table ${table.baseTableRow.tableName}")
      table.ddl.create
    }
  }

  def withSession[T](work: Session => T) = db withSession work
}


