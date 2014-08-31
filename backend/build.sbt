name := "class-ninja-backend"

version := "1.0"

libraryDependencies ++= Seq(
  "net.databinder.dispatch" %% "dispatch-core" % "0.11.1",
  "net.databinder.dispatch" %% "dispatch-tagsoup" % "latest.integration",
  "com.typesafe.slick" %% "slick" % "latest.integration",
  "com.h2database" % "h2" % "latest.integration",
  "mysql" % "mysql-connector-java" % "latest.integration",
  "ch.qos.logback" % "logback-classic" % "latest.integration",
  "com.typesafe.scala-logging" %% "scala-logging-slf4j" % "latest.integration",
  "com.rabbitmq" % "amqp-client" % "latest.integration",
  "org.scala-lang" %% "scala-pickling" % "0.8.0",
  "com.notnoop.apns" % "apns" % "0.2.3"
)
