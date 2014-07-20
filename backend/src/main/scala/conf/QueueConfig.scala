package conf

import com.typesafe.config.Config

case class QueueConfig (
  host: String,
  port: Int,
  name: String
)

object QueueConfig {
  def apply(queueConfig: Config): QueueConfig = {
    QueueConfig(
      queueConfig.getString("host"),
      queueConfig.getInt("port"),
      queueConfig.getString("name")
    )
  }
}
