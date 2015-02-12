package notifications

import com.notnoop.apns.{APNS, ApnsService}
import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{Environment, APNSConfig, APNSEnvironmentConfig}
import model.NotificationInterface

object APNSManager extends LazyLogging {
  type APNSPayload = String

  private val apnsConfig = APNSConfig(Environment("apns"))
  private val productionService = createAPNSService(apnsConfig, sandbox = false)
  private val sandboxService = createAPNSService(apnsConfig, sandbox = true)

  private def createAPNSService(apnsConfig: APNSConfig, sandbox: Boolean): ApnsService = {
    val apnsEnvConf: APNSEnvironmentConfig = apnsConfig.getEnvironmentConfiguration(sandbox)
    APNS.newService()
      .withCert(apnsEnvConf.certificatePath, apnsEnvConf.certificatePassword)
      .withAppleDestination(!sandbox)
      .build()
  }

  def sendPayload(payload: APNSPayload, notificationInterfaces: Seq[NotificationInterface]) = {
    notificationInterfaces foreach { notificationInterface: NotificationInterface =>
      val apnsService = notificationInterface.kind match {
        case "iOS" => productionService
        case "iOS-sandbox" => sandboxService
        case x => throw new IllegalArgumentException(s"Can't send an APNS to a notification interface of an unknown kind: $x")
      }
      logger.info(s"Sending APN to ${notificationInterface.notificationInterfaceName}: $payload")
      apnsService.push(notificationInterface.notificationInterfaceKey, payload)
    }
  }

  def payload(message: String, customFields: Map[String, String] = Map.empty): APNSPayload = {
    val payloadBuilder = APNS.newPayload()
      .alertBody(message)
      .sound("course_alert.aiff")
      .noActionButton()
    customFields.foldLeft(payloadBuilder) { case (b, kv) =>
      b.customField(kv._1, kv._2)
    }.build()
  }
}
