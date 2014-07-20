package model

import scala.slick.driver.MySQLDriver.simple._

case class User(phoneNumber: String,
                credits: Int,
                email: Option[String])

class Users(tag: Tag) extends Table[User](tag, "userprofile") {
  def phoneNumber = column[String]("phonenumber", O.NotNull, O.PrimaryKey)
  def credits = column[Int]("credits", O.NotNull)
  def email = column[Option[String]]("email", O.Nullable, O.Default(None))

  def * = (phoneNumber, credits, email) <> (User.tupled, User.unapply)
}
