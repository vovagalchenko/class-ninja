package notifications

import com.rabbitmq.client.QueueingConsumer.Delivery
import com.rabbitmq.client.{QueueingConsumer, Channel, Connection, ConnectionFactory}
import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{Environment, MessageExchangeConfig}
import model.{DBManager, Target, Event}

import scala.slick.driver.MySQLDriver.simple._
import scala.pickling._
import json._

object NotificationQueue {
  def withMessageExchange[T](work: (MessageExchange => T)): T = {
    val notificationDaemonConf = Environment("notifications")
    val queueProperties: MessageExchangeConfig = MessageExchangeConfig(notificationDaemonConf.getConfig("queue"))
    val factory: ConnectionFactory = new ConnectionFactory
    factory.setHost(queueProperties.host)
    factory.setPort(queueProperties.port)
    val connection: Connection = factory.newConnection
    val exchange: MessageExchange = new MessageExchange(connection, queueProperties)

    val result: T = work(exchange)

    exchange.close()
    connection.close()

    result
  }
}

class MessageExchange(connection: Connection, exchangeConfig: MessageExchangeConfig) extends LazyLogging {
  private val channel: Channel = {
    val channel: Channel = connection.createChannel
    channel.exchangeDeclare(exchangeConfig.name, "fanout", true)
    channel
  }

  def sendNotification(target: Target, event: Event): Unit = {
    val msg: String = (target.targetId, event.primaryKey).pickle.value
    channel.basicPublish(exchangeConfig.name, "", null, msg.getBytes)
    logger.info(s"Sent msg to exchange <${exchangeConfig.name}>: $msg")
  }

  // This method never exits
  def enterNotificationReceivingRunloop(queueName: String)(alertProcessor: (Target, Event, Session) => Unit)
                                       (implicit dbManager: DBManager) = {
    channel.queueDeclare(queueName, true, false, false, null)
    channel.queueBind(queueName, exchangeConfig.name, "")
    val consumer = new QueueingConsumer(channel)
    channel.basicConsume(queueName, true, consumer)
    logger.info(s"Listening on <$queueName> for $exchangeConfig")

    while (true) {
      val delivery: Delivery = consumer.nextDelivery
      val msgString = new String(delivery.getBody)
      logger.info(s"Received '$msgString'")
      val message = JSONPickle(msgString)
      val (targetId, eventId): (Int, String) = message.unpickle[(Int, String)]
      dbManager withSession { implicit session =>
        val target = dbManager.targets.filter(_.targetId === targetId).first
        val event = dbManager.events.filter(_.eventId === eventId).first
        alertProcessor(target, event, session)
      }
    }
  }

  def close() = channel.close()
}
