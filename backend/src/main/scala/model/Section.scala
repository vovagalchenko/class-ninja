package model

import model.SchoolId.SchoolId

case class Section(
  sectionId: Option[Int],
  sectionName: String,
  courseId: String,
  events: Seq[Event],
  schoolId: SchoolId
)

case class Event(
  eventId: Option[Int],
  schoolEventId: String,
  eventType: String,
  sectionId: Int,
  timesAndLocations: String,
  schoolId: SchoolId
)
