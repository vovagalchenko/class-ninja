package model

import scala.slick.driver.MySQLDriver.simple._
import scala.slick.jdbc.meta.MTable
import com.typesafe.config.Config

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
  val sections = TableQuery[Sections]
  val events = TableQuery[Events]
  initialize()

  private def initialize() = {
    createIfNeeded(schools)
    createIfNeeded(departments)
    createIfNeeded(courses)
    createIfNeeded(sections)
    createIfNeeded(events)
  }

  def createIfNeeded[T <: Table[_]](table: TableQuery[T]) = db withSession { implicit session: Session =>
    if (MTable.getTables(table.baseTableRow.tableName).list.isEmpty) {
      table.ddl.create
    }
  }

  def withSession[T](work: Session => T) = db withSession work
}

object DBConfig {
  def apply(config: Config): DBConfig = {
    val dsn = config.getString("dsn")
    val username = getOptionalConfString(config, "username")
    val password = getOptionalConfString(config, "password")
    DBConfig(dsn, username, password)
  }

  private def getOptionalConfString(config: Config, key: String): Option[String] = {
    if (config.hasPath(key)) {
      Option(config.getString(key))
    } else {
      None
    }
  }
}
case class DBConfig(mySqlEndpoint: String, user: Option[String], password: Option[String])
