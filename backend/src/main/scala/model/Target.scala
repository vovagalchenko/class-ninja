package model

import scala.slick.driver.MySQLDriver.simple._

case class Target(targetId: Int,
                  eventId: String,
                  userPhoneNumber: String)

class Targets(tag: Tag) extends Table[Target](tag, "targets") {
  def targetId = column[Int]("target_id", O.PrimaryKey, O.AutoInc)
  def eventId = column[String]("event_id", O.NotNull)
  def userPhoneNumber = column[String]("user_phone_number", O.NotNull)

  def eventIndex = index("tgt_event_id_index", eventId, unique = false)
  def userPhoneNumberIndex = index("tgt_phone_number_index", userPhoneNumber, unique = false)
  def user = foreignKey("tgt_user_fk", userPhoneNumber, TableQuery[Users])(_.phoneNumber)
  def event = foreignKey("tgt_event_fk", eventId, TableQuery[Events])(_.eventId)

  def * = (targetId, eventId, userPhoneNumber) <> (Target.tupled, Target.unapply)
}
