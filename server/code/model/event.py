from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer, TEXT

class Event(Base, Ninja_Model_Mixin):
    __tablename__ = 'events'
    event_id = Column('event_id', String(254), primary_key = True)
    school_specific_event_id = Column('school_specific_event_id', String(254), nullable = False)
    event_type = Column('event_type', String(254), nullable = False)
    times_and_locations = Column('times_and_locations', TEXT, nullable = False)
    number_enrolled = Column('number_enrolled', Integer, nullable = False)
    enrollment_cap = Column('enrollment_cap', Integer, nullable = False)
    number_waitlisted = Column('number_waitlisted', Integer, nullable = False)
    waitlist_capacity = Column('waitlist_capacity', Integer, nullable = False)
    status = Column('status', String(254), nullable = False)
    section_id = Column('section_id', String(254), ForeignKey("sections.section_id"), nullable = False)
    school_id = Column('school_id', Integer, ForeignKey("schools.school_id"),  nullable = False)   
