name := "class-ninja-backend"

version := "1.0"

resolvers += Resolver.sonatypeRepo("snapshots")

libraryDependencies ++= Seq(
  "net.databinder.dispatch" %% "dispatch-core" % "0.11.1",
  "net.databinder.dispatch" %% "dispatch-tagsoup" % "latest.integration",
  "com.typesafe.slick" %% "slick" % "latest.integration",
  "com.h2database" % "h2" % "latest.integration",
  "mysql" % "mysql-connector-java" % "latest.integration",
  "ch.qos.logback" % "logback-classic" % "latest.integration",
  "com.typesafe.scala-logging" %% "scala-logging-slf4j" % "latest.integration",
  "com.rabbitmq" % "amqp-client" % "latest.integration",
  "org.scala-lang" %% "scala-pickling" % "0.9.0-SNAPSHOT"
)
