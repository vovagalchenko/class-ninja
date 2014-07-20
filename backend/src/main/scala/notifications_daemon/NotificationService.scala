package notifications_daemon

import com.rabbitmq.client.QueueingConsumer.Delivery
import com.rabbitmq.client.{Channel, Connection, ConnectionFactory, QueueingConsumer}
import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{Environment, QueueConfig}

object NotificationService extends LazyLogging {
  def main(args: Array[String]): Unit = {
    val notificationDaemonConf = Environment("notifications-daemon")
    val queueProperties = QueueConfig(notificationDaemonConf.getConfig("queue"))

    val connectionFactory: ConnectionFactory = new ConnectionFactory()
    connectionFactory.setHost(queueProperties.host)
    connectionFactory.setPort(queueProperties.port)
    logger.info(s"Listening on queue: $queueProperties")
    val connection: Connection = connectionFactory.newConnection()
    val channel: Channel = connection.createChannel()
    channel.queueDeclare(
      queueProperties.name, // queueName
      true,                 // durable
      false,                // exclusive
      false,                // autoDelete
      null                  // arguments
    )
    val consumer: QueueingConsumer = new QueueingConsumer(channel);
    channel.basicConsume(queueProperties.name, true, consumer);

    while (true) {
      val delivery: Delivery = consumer.nextDelivery
      val message = new String(delivery.getBody)
      logger.info(" [x] Received '" + message + "'");
    }
  }
}