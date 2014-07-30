from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer
from sqlalchemy.orm import relationship, backref

class Section(Base, Ninja_Model_Mixin):
    __tablename__ = 'sections'
    section_id = Column('section_id', String(254), primary_key = True)
    section_name = Column('section_name', String(254), nullable = False)
    staff_name = Column('staff_name', String(254), nullable = False)
    course_id = Column('course_id', String(254), ForeignKey("courses.course_id"), nullable = False)
    school_id = Column('school_id', Integer, ForeignKey("schools.school_id"), nullable = False)
