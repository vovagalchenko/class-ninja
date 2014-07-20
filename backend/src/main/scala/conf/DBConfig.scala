package conf

import com.typesafe.config.Config

object DBConfig {
  def apply(config: Config): DBConfig = {
    val dsn = config.getString("dsn")
    val username = getOptionalConfString(config, "username")
    val password = getOptionalConfString(config, "password")
    DBConfig(dsn, username, password)
  }

  private def getOptionalConfString(config: Config, key: String): Option[String] = {
    if (config.hasPath(key)) {
      Option(config.getString(key))
    } else {
      None
    }
  }
}
case class DBConfig(mySqlEndpoint: String, user: Option[String], password: Option[String])
