package course_refresh

import java.util.concurrent.TimeUnit

import com.typesafe.scalalogging.slf4j.LazyLogging
import conf.{DBConfig, Environment}
import model.SchoolId.SchoolId
import model._
import notifications.{MessageExchange, NotificationQueue}
import ucla.UCLACourseFetchManager

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration.Duration
import scala.concurrent.{Await, Future}
import scala.slick.driver.MySQLDriver.simple._

object CourseFetch extends LazyLogging {
  def main(args: Array[String]) = {
    require(args.length == 2, {
      logger.error("Must pass in two parameters to the course fetch process: the school id and the mode (ALL|EVENTS|TARGETS)")
    })
    val school: SchoolId = SchoolId(args(0).toInt)
    val (shouldRefreshOfferedCourses, shouldRefreshAllEvents) = args(1) match {
      case "ALL"     => (true, true)
      case "EVENTS"  => (false, true)
      case "TARGETS" => (false, false)
      case _ => throw new Exception(s"Don't understand the mode argument <${args(1)}>")
    }
    logger.info(s"Starting course fetch for ${school.toString} refreshing <${args(1)}>")

    val courseFetchConf = Environment("course-fetch")
    logger.info(s"Going to use conf: $courseFetchConf")

    val startTime = System.currentTimeMillis
    try {
      val databaseConf = courseFetchConf.getConfig("database")
      implicit val dbManager = new DBManager(DBConfig(databaseConf))
      dbManager withSession { implicit session =>
        NotificationQueue withMessageExchange { implicit messageExchange =>
          performCourseFetch(school, shouldRefreshOfferedCourses, shouldRefreshAllEvents)
        }
      }
      logger.info(s"Finished course fetch for $school refreshing <${args(1)}>")
    } catch {
      case e: Throwable =>
        logger.error("Uncaught exception", e)
        throw e
    } finally {
      // Need to call shutdown to make sure dispatch is dead and the process can exit
      HTTPManager.shutdown()
      val endTime = System.currentTimeMillis
      val duration = Duration(endTime - startTime, TimeUnit.MILLISECONDS)
      logger.info(s"Execution took ${duration.toMinutes} m ${duration.toSeconds - Duration(duration.toMinutes, TimeUnit.MINUTES).toSeconds} s")
      System.exit(1)
    }
  }

  private def performCourseFetch(school: SchoolId, refreshOfferedCourses: Boolean, refreshAllEvents: Boolean)
                                (implicit dbManager: DBManager, session: Session, messageExchange: MessageExchange) = {
    val schoolManager: SchoolManager = school match {
      case SchoolId.UCLA => UCLACourseFetchManager
    }

    val departmentAndCourseFetchManager = if (refreshOfferedCourses) {
      Some(schoolManager)
    } else {
      None
    }
    val allWorkFuture = withDepartmentsAndCourses(departmentAndCourseFetchManager, school) { case (department: Department, courses: Seq[Course]) =>

      val sectionIds: Seq[String] = dbManager.sections
        .filter(_.courseId inSet courses.map(_.primaryKey))
        .map(_.sectionId)
        .list
      val eventIds: Seq[String] = dbManager.events
        .filter(_.sectionId inSet sectionIds)
        .map(_.eventId)
        .list
      val targetEventQuery = for {
        t <- dbManager.targets.filter(_.eventId inSet eventIds)
        e <- dbManager.events if t.eventId === e.eventId
      } yield (t, e)
      val targetEvents: Seq[(Target, Event)] = targetEventQuery.list
      val targetEventTuplesByEventId: Map[String, Seq[(Target, Event)]] = targetEvents.groupBy(_._2.primaryKey)

      schoolManager.fetchEvents(courses) map { events: Seq[(Section, Seq[Event])] =>
        // Update the MySQL. Technically, might be nice to do this transactionally, however at this point, it's not
        // really necessary for this update to be transactional. There are rarely going to be multiple writers
        // touching the same rows, and they're all trying to do the same thing, so it's OK if they
        // step over each other.
        if (refreshOfferedCourses) {
          dbManager.departments.insertOrUpdate(department)
          courses foreach { course: Course =>
            dbManager.courses.insertOrUpdate(course)
          }
        }
        events foreach { case (section: Section, sectionsEvents: Seq[Event]) =>
          dbManager.sections.insertOrUpdate(section)
          sectionsEvents foreach { event: Event =>
            dbManager.events.insertOrUpdate(event)
            targetEventTuplesByEventId.get(event.primaryKey) map { targetEventTuples: Seq[(Target, Event)] =>
              targetEventTuples foreach { case (target: Target, oldEvent: Event) =>
                if (schoolManager.shouldAlert(oldEvent, event)) {
                  logger.info(s"Queuing notifications about $target")
                  messageExchange.sendNotification(target, event)
                }
              }
            }
          }
        }
        logger.info(s"Done updating <${courses.length}> courses at ${school.toString}'s ${department.name}")
      }
    }
    Await.result(allWorkFuture, Duration(1, TimeUnit.HOURS))
  }

  private def withDepartmentsAndCourses[T](courseFetchManager: Option[SchoolManager], school: SchoolId)
                                          (work: (Department, Seq[Course]) => Future[T])
                                          (implicit dbManager: DBManager, session: Session): Future[Seq[T]] = {
    courseFetchManager match {
      case Some(fetchManager) =>
        fetchManager.fetchDepartments flatMap { departments: Seq[Department] =>
          logger.info(s"Fetched the list of <${departments.length}> departments from ${school.toString}'s website")
          val schoolSpecificIds = departments.map(_.schoolSpecificId)
          require(schoolSpecificIds.distinct.size == schoolSpecificIds.size, {
            logger.error(s"There are duplicate departments in school ${school.toString}")
          })
          val currentTermCode = dbManager.schools.filter(_.schoolId === school.id).first.currentTermCode
          val allWork = departments map { freshDepartment: Department =>
            val futureResultsOfWork: Future[T] = fetchManager.fetchCourses(currentTermCode, freshDepartment) flatMap { courses: Seq[Course] =>
              val departmentSpecificCourseIds = courses.map(_.departmentSpecificCourseId)
              require(departmentSpecificCourseIds.distinct.size == departmentSpecificCourseIds.size, {
                logger.error(s"There exist duplicate courses in ${school.toString}'s <${freshDepartment.name}> department")
              })
              work(freshDepartment, courses)
            }
            futureResultsOfWork
            // This is not clear to me, but for whatever reason, if I don't block here and instead flatMap on the result
            // of fetchDepartment, the script never finishes or fails with weird connection errors. It's not critical
            // for this to be non-blocking as we're already fetching all of the courses for a given department
            // concurrently. Still... it'd be super nice to understand this.
//            Await.result(futureResultsOfWork, Duration(1, TimeUnit.HOURS))
          }
          Future.sequence(allWork)
        }
      case None =>
        val workResultFutures = dbManager.departments.filter(_.schoolId === school.id).list map { department: Department =>
          val courses = dbManager.courses.filter(_.departmentId === department.primaryKey).list
          work(department, courses)
        }
        Future sequence workResultFutures
    }
  }
}

abstract class SchoolManager {
  def fetchDepartments: Future[Seq[Department]]
  def fetchCourses(term: String, department: Department): Future[Seq[Course]]
  def fetchEvents(courses: Seq[Course]): Future[Seq[(Section, Seq[Event])]]

  def shouldAlert(oldEvent: Event, newEvent: Event): Boolean
}
