package course_refresh

import com.rabbitmq.client.{Channel, Connection, ConnectionFactory}
import conf.{Environment, QueueConfig}

object NotificationQueueProducer {
  def withMQ[T](work: (MessageQueue => T)): T = {
    val notificationDaemonConf = Environment("notifications-daemon")
    val queueProperties: QueueConfig = QueueConfig(notificationDaemonConf.getConfig("queue"))
    val factory: ConnectionFactory = new ConnectionFactory
    factory.setHost(queueProperties.host)
    factory.setPort(queueProperties.port)
    val connection: Connection = factory.newConnection
    val mq: MessageQueue = new MessageQueue(connection, queueProperties)

    val result: T = work(mq)

    mq.close()
    connection.close()

    result
  }
}

class MessageQueue(connection: Connection, queueConfig: QueueConfig) {
  private val channel: Channel = {
    val channel: Channel = connection.createChannel
    channel.queueDeclare(queueConfig.name, true, false, false, null)
    channel
  }

  def sendMessage(msg: String) = {
    channel.basicPublish("", queueConfig.name, null, msg.getBytes)
    println(s"Sent msg to <${queueConfig.name}>: $msg")
  }

  def close() = channel.close()
}
