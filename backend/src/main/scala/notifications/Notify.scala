package notifications

import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{Environment, DBConfig}
import model.{NotificationInterface, DBManager}
import scala.slick.driver.MySQLDriver.simple._

object Notify extends LazyLogging {
  def main(args: Array[String]): Unit = {
    val inputLines = io.Source.stdin.getLines().toSeq
    val phoneNumbers = inputLines.map {
      case phoneNumber if phoneNumber.matches("\\d{10}") => phoneNumber
      case inputLine =>
        println(s"Unexpected user phone number: $inputLine")
        System.exit(1)
        ""
    }

    val courseFetchConf = Environment("course-fetch")
    implicit val dbManager = new DBManager(DBConfig(courseFetchConf.getConfig("database")))
    dbManager.withSession { implicit session =>
      val notificationInterfaces: Seq[NotificationInterface] = dbManager
        .notificationInterfaces
        .filter(_.userPhoneNumber inSet phoneNumbers)
        .filter(_.kind inSet Seq("iOS", "iOS-sandbox"))
        .list
      val phoneNumberToNotificationInterfaces = notificationInterfaces.groupBy(_.userPhoneNumber)
      phoneNumbers.foreach {
        case phoneNumber if !phoneNumberToNotificationInterfaces.contains(phoneNumber) =>
          println(s"No iOS notification interface was found for phone number $phoneNumber")
        case _ =>
      }

      val numDevices = notificationInterfaces.length
      val message = messageInputHelper(numDevices)
      confirmationHelper(numDevices)

      APNSManager.sendPayload(APNSManager.payload(message), notificationInterfaces)
    }
  }

  private def messageInputHelper(numDevices: Int): String = {
    println(s"Please enter the message to send to $numDevices devices:")
    val line = io.Source.stdin.getLines().next()
    if (line.size >= 256) {
      println(s"The string you're sending is too long: ${line.size} characters. The whole APNS payload can't be larger than 256 bytes.")
      messageInputHelper(numDevices)
    } else {
      line
    }
  }

  private def confirmationHelper(numDevices: Int): Unit = {
    print(s"We are all set to send your message to $numDevices devices. If you're ready to proceed, type 'yes': ")
    val line = io.Source.stdin.getLines().next()
    line match {
      case "yes" =>
      case "no" =>
        println("OK, bye")
        System.exit(0)
      case _ => confirmationHelper(numDevices)
    }
  }
}
