package model

import model.SchoolId._
import core.StringUtilities._

case class Event(
                  schoolSpecificEventId: String,
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
    s"${sectionId}_$schoolSpecificEventId".toSafeId
  }
}

case class Spacetime(
                      weekdays: String,
                      timeInterval: String,
                      location: String
                      )
