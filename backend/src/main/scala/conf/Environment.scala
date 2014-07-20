package conf

import java.io.File

import com.typesafe.config.{Config, ConfigFactory}

object Environment {

  private val environmentConf: Config = {
    val file = new File("environment.conf")
    val confFromFile = ConfigFactory.parseFile(file)
    if (confFromFile.isEmpty) {
      ConfigFactory.load("environment")
    } else {
      confFromFile
    }
  }

  def apply(configName: String): Config = {
    environmentConf.getConfig(configName)
  }
}
