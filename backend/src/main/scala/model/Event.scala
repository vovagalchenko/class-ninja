package model

import course_refresh.StringUtilities._
import model.SchoolId._

import scala.slick.driver.MySQLDriver.simple._
import scala.util.parsing.json.{JSON, JSONArray, JSONObject}

case class Event(
                  schoolSpecificEventId: Option[String],
                  eventType: String,
                  timesAndLocations: Seq[Spacetime],
                  numberEnrolled: Int,
                  enrollmentCapacity: Int,
                  numWaitlisted: Int,
                  waitlistCapacity: Int,
                  status: String,
                  sectionId: String,
                  schoolId: SchoolId
) {
  def primaryKey: String = {
    s"${sectionId}_${schoolSpecificEventId.get}".toSafeId
  }
}

object Spacetime {
  def apply(jsonString: String): Seq[Spacetime] = {
    JSON.parseFull(jsonString) match {
      case Some(x) =>
        val parsedJson = x.asInstanceOf[List[Map[String, String]]]
        parsedJson map { spaceTimeMap: Map[String, String] =>
          Spacetime(
            spaceTimeMap("weekdays"),
            spaceTimeMap("timeInterval"),
            spaceTimeMap("location")
          )
        }
      case _ => throw new Exception(s"Can't parse spacetime json: $jsonString")
    }
  }

  def toJSON(spacetimes: Seq[Spacetime]): String = {
    val jsonSerializable: List[JSONObject] = spacetimes.map({ spacetime: Spacetime =>
      JSONObject(
        Map(
          "weekdays" -> spacetime.weekdays,
          "timeInterval" -> spacetime.timeInterval,
          "location" -> spacetime.location
        )
      )
    }).toList
    JSONArray(jsonSerializable).toString
  }
}

case class Spacetime(
  weekdays: String,
  timeInterval: String,
  location: String
)

class Events(tag: Tag) extends Table[Event](tag, "events") {
  def eventId = column[String]("event_id", O.PrimaryKey)
  def schoolSpecificEventId = column[String]("school_specific_event_id")
  def eventType = column[String]("event_type")
  def timesAndLocations = column[String]("times_and_locations", O.DBType("TEXT"))
  def numberEnrolled = column[Int]("number_enrolled")
  def enrollmentCapacity = column[Int]("enrollment_cap")
  def numberWaitlisted = column[Int]("number_waitlisted")
  def waitlistCapacity = column[Int]("waitlist_capacity")
  def status = column[String]("status")
  def sectionId = column[String]("section_id")
  def schoolId = column[Int]("school_id")

  def school = foreignKey("evt_school_fk", schoolId, TableQuery[Schools])(_.schoolId)
  def section = foreignKey("evt_section_fk", sectionId, TableQuery[Sections])(_.sectionId)

  def * = (
    eventId,
    schoolSpecificEventId,
    eventType,
    timesAndLocations,
    numberEnrolled,
    enrollmentCapacity,
    numberWaitlisted,
    waitlistCapacity,
    status,
    sectionId,
    schoolId
  ) <> (createEvent, createTuple)

  private def createEvent(tuple: (String, String, String, String, Int, Int, Int, Int, String, String, Int)): Event = {
    Event(
      Option(tuple._2), tuple._3, Spacetime(tuple._4), tuple._5, tuple._6, tuple._7, tuple._8, tuple._9, tuple._10, SchoolId(tuple._11)
    )
  }

  private def createTuple(event: Event): Option[(String, String, String, String, Int, Int, Int, Int, String, String, Int)] = {
    Option(
      (
        event.primaryKey,
        event.schoolSpecificEventId.get,
        event.eventType,
        Spacetime.toJSON(event.timesAndLocations),
        event.numberEnrolled,
        event.enrollmentCapacity,
        event.numWaitlisted,
        event.waitlistCapacity,
        event.status,
        event.sectionId,
        event.schoolId.id
      )
    )
  }
}