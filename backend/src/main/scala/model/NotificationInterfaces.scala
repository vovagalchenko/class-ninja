package model

import scala.slick.driver.MySQLDriver.simple._

case class NotificationInterface(
  notificationInterfaceId: Int,
  userPhoneNumber: String,
  kind: String,
  notificationInterfaceKey: String,
  notificationInterfaceName: String
)

class NotificationInterfaces(tag: Tag) extends Table[NotificationInterface](tag, "notification_interfaces") {
  def notificationInterfaceId = column[Int]("notification_interface_id", O.PrimaryKey, O.AutoInc)
  def userPhoneNumber = column[String]("user_phone_number")
  def kind = column[String]("kind")
  def notificationInterfaceKey = column[String]("notification_interface_key")
  def notificationInterfaceName = column[String]("notification_interface_name")

  def user = foreignKey("notification_interface_user_fk", userPhoneNumber, TableQuery[Users])(_.phoneNumber)
  def kindUserPhoneNumberIndex = index("kind_user_phone_number_idx", (kind, userPhoneNumber))

  def * = (notificationInterfaceId, userPhoneNumber, kind, notificationInterfaceKey, notificationInterfaceName) <>
    (NotificationInterface.tupled, NotificationInterface.unapply)

}
