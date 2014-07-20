package notifications

import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{DBConfig, Environment}
import model.{Event, Target}
import model.DBManager

object iOSPushNotificationService extends LazyLogging {
  def main(args: Array[String]): Unit = {
    val dbConfig = DBConfig(Environment("course-fetch").getConfig("database"))
    implicit val dbManager = new DBManager(dbConfig)
    NotificationQueue withMessageExchange { messageExchange =>
      messageExchange.enterNotificationReceivingRunloop("ios") { (target: Target, event: Event) =>
        logger.info(s"Processing notification for $target")
      }
    }
  }
}