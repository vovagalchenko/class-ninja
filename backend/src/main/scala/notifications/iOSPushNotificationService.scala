package notifications

import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{DBConfig, Environment}
import model._
import scala.slick.driver.MySQLDriver.simple._

object iOSPushNotificationService extends LazyLogging {
  def main(args: Array[String]): Unit = {
    val dbConfig = DBConfig(Environment("course-fetch").getConfig("database"))
    implicit val dbManager = new DBManager(dbConfig)
    NotificationQueue withMessageExchange { messageExchange =>
      messageExchange.enterNotificationReceivingRunloop("ios") { (target: Target, event: Event, session: Session) =>
        try {
          logger.info(s"Processing notification for $target")
          implicit val s = session
          val sectionCourseQuery = for {
            s <- dbManager.sections.filter(_.sectionId === event.sectionId)
            c <- dbManager.courses if s.courseId === c.courseId
          } yield (s, c)
          val sectionCourseTuple: (Section, Course) = sectionCourseQuery.first
          val course = sectionCourseTuple._2
          val alertBody: String = event.status match {
            case "Open" => s"${event.eventType} of ${course.name} is now available to register for!"
            case "W-List" => s"Waitlist for ${event.eventType} of ${course.name} just opened up!"
          }
          val payload: String = APNSManager.payload(alertBody, Map("courseId" -> course.primaryKey))
          logger.info(s"Calculated payload: $payload")
          val notificationInterfaces: Seq[NotificationInterface] = dbManager.notificationInterfaces
            .filter(_.userPhoneNumber === target.userPhoneNumber)
            .filter(_.kind inSet "iOS" :: "iOS-sandbox" :: Nil)
            .list
          if (notificationInterfaces.length == 0) {
            logger.error(s"User <${target.userPhoneNumber}> hasn't set up any notification interfaces.")
          } else {
            APNSManager.sendPayload(payload, notificationInterfaces)
          }
        } catch {
          case e: Throwable =>
            logger.error(s"Uncaught exception while processing notification for $target", e)
        }
      }
    }
  }

}