package conf

import com.typesafe.config.Config

object APNSConfig {
  def apply(config: Config): APNSConfig = {
    APNSConfig(
      APNSEnvironmentConfig(config.getConfig("dev"), true),
      APNSEnvironmentConfig(config.getConfig("prod"), false)
    )
  }
}

case class APNSConfig(
  devConfiguration: APNSEnvironmentConfig,
  prodConfiguration: APNSEnvironmentConfig
) {
  require(devConfiguration.sandbox && !prodConfiguration.sandbox)

  def getEnvironmentConfiguration(sandbox: Boolean): APNSEnvironmentConfig = {
    if (sandbox) {
      devConfiguration
    } else {
      prodConfiguration
    }
  }
}

object APNSEnvironmentConfig {
  def apply(config: Config, sandbox: Boolean): APNSEnvironmentConfig = {
    APNSEnvironmentConfig(
      config.getString("cert-path"),
      config.getString("cert-password"),
      sandbox
    )
  }
}

case class APNSEnvironmentConfig(
  certificatePath: String,
  certificatePassword: String,
  sandbox: Boolean
)
