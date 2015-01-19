package term_switch

import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{DBConfig, Environment}
import course_refresh.{HTTPManager, CourseFetch}
import model._
import notifications.APNSManager
import scala.slick.driver.MySQLDriver.simple._
import scala.util.control.NonFatal

object TermSwitch extends LazyLogging {
  def main(args: Array[String]): Unit = {
    require(args.length == 3, {
      throw new IllegalArgumentException(
        "Must pass in three parameters to the course fetch process: the school id, the new term code and term name."
      )
    })
    val schoolId = SchoolId(args(0).toInt)
    val newTermCode = args(1)
    val newTermName = args(2)
    val courseFetchConf = Environment("course-fetch")

    implicit val dbManager = new DBManager(DBConfig(courseFetchConf.getConfig("database")))
    dbManager withSession { implicit session =>
      val school = dbManager.schools.filter(_.schoolId === schoolId.id).firstOption.getOrElse {
        throw new IllegalArgumentException(s"There's no school for id: $schoolId")
      }
      if (newTermCode == school.currentTermCode) {
        throw new IllegalArgumentException(s"$schoolId's current term code is already $newTermCode")
      }

      confirmationHelper(school, newTermName, newTermCode)

      val usersToAlert = session withTransaction {
        val targetQuery = for {
          e <- dbManager.events.filter(_.schoolId === school.schoolId)
          t <- dbManager.targets if e.eventId === t.eventId
        } yield t
        val targets: Seq[Target] = targetQuery.list

        dbManager.targets.filter(_.targetId inSet targets.map(_.targetId)).delete
        dbManager.events.filter(_.schoolId === school.schoolId).delete
        dbManager.sections.filter(_.schoolId === school.schoolId).delete
        dbManager.courses.filter(_.schoolId === school.schoolId).delete
        dbManager.departments.filter(_.schoolId === school.schoolId).delete

        dbManager.schools
          .filter(_.schoolId === school.schoolId)
          .map { s => (s.currentTermCode, s.currentTermName)}
          .update((newTermCode, newTermName))

        try {
          logger.info(s"Fetching courses for ${school.schoolName}")
          CourseFetch.performCourseFetch(
            school = schoolId,
            refreshOfferedCourses = true,
            refreshAllEvents = true,
            messageExchangeOption = None)
          logger.info("Will commit the database changes")
          dbManager.users.filter(_.phoneNumber inSet targets.map(_.userPhoneNumber)).list
        } catch {
          case NonFatal(e) =>
            logger.error("Uncaught exception while performing course fetch", e)
            session.rollback()
            List[User]()
        } finally {
          HTTPManager.shutdown()
        }
      }

      if (usersToAlert.size == 0) {
        logger.info("No users to notify.")
        return
      }
      logger.info(s"Need to notify the following ${usersToAlert.size} users:\n\t${usersToAlert.map(_.phoneNumber).mkString("\n\t")}")

      val notificationInterfaces: Seq[NotificationInterface] = dbManager.notificationInterfaces
        .filter(_.userPhoneNumber inSet usersToAlert.map(_.phoneNumber))
        .filter(_.kind inSet "iOS" :: "iOS-sandbox" :: Nil)
        .list
      val payload = APNSManager.payload(s"${newTermName} is now tracked for ${school.schoolName}. Your targets from the previous term have been cleared.")
      APNSManager.sendPayload(payload, notificationInterfaces)
    }
  }

  private def confirmationHelper(school: School, newTermName: String, newTermCode: String) {
    print(s"Are you sure you want to change ${school.schoolName}'s current term to be $newTermName ($newTermCode)? (y/n) ")
    val line = io.Source.stdin.getLines().next()
    line match {
      case "y" =>
      case "n" =>
        println("OK, bye")
        System.exit(0)
      case _ => confirmationHelper(school, newTermName, newTermCode)
    }
  }

}
