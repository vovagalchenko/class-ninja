package notifications

import com.notnoop.apns.{ApnsService, APNS}
import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{APNSEnvironmentConfig, APNSConfig, DBConfig, Environment}
import model._
import scala.slick.driver.MySQLDriver.simple._

object iOSPushNotificationService extends LazyLogging {
  def main(args: Array[String]): Unit = {
    val apnsConfig = APNSConfig(Environment("apns"))
    val sandboxService = createAPNSService(apnsConfig, sandbox = true)
    val prodService = createAPNSService(apnsConfig, sandbox = false)

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
          val payload: String = APNSPayloadForEvent(event, sectionCourseTuple._2)
          logger.info(s"Calculated payload: $payload")
          val notificationInterfaces: Seq[NotificationInterface] = dbManager.notificationInterfaces
            .filter(_.userPhoneNumber === target.userPhoneNumber)
            .filter(_.kind inSet "iOS" :: "iOS-sandbox" :: Nil)
            .list
          if (notificationInterfaces.length == 0) {
            logger.error(s"User <${target.userPhoneNumber}> hasn't set up any notification interfaces.")
          }
          notificationInterfaces foreach { notificationInterface: NotificationInterface =>
            val apnsService = notificationInterface.kind match {
              case "iOS" => prodService
              case "iOS-sandbox" => sandboxService
            }
            logger.info(s"Sending APN to ${notificationInterface.notificationInterfaceName} for $event")
            apnsService.push(notificationInterface.notificationInterfaceKey, payload)
          }
        } catch {
          case e: Throwable =>
            logger.error(s"Uncaught exception while processing notification for $target", e)
        }
      }
    }
  }

  def createAPNSService(apnsConfig: APNSConfig, sandbox: Boolean): ApnsService = {
    val apnsEnvConf: APNSEnvironmentConfig = apnsConfig.getEnvironmentConfiguration(sandbox)
    APNS.newService()
      .withCert(apnsEnvConf.certificatePath, apnsEnvConf.certificatePassword)
      .withAppleDestination(!sandbox)
      .build()
  }

  def APNSPayloadForEvent(event: Event, course: Course): String = {
    val alertBody: String = event.status match {
      case "Open" => s"${event.eventType} of ${course.name} is now available to register for!"
      case "W-List" => s"Waitlist for ${event.eventType} of ${course.name} just opened up!"
    }
    APNS.newPayload()
      .alertBody(alertBody)
      .sound("course_alert.aiff")
      .noActionButton()
      .customField("course_id", course.primaryKey)
      .build()
  }

}