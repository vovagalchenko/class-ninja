package conf

import com.typesafe.config.Config

case class MessageExchangeConfig (
  host: String,
  port: Int,
  name: String
)

object MessageExchangeConfig {
  def apply(queueConfig: Config): MessageExchangeConfig = {
    MessageExchangeConfig(
      queueConfig.getString("host"),
      queueConfig.getInt("port"),
      queueConfig.getString("exchange")
    )
  }
}
