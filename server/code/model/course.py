from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer
from model.section import Section
from model.school import School
from model.department import Department
from sqlalchemy.orm import backref, relationship

class Course(Base, Ninja_Model_Mixin):
    __tablename__ = 'courses'
    course_id = Column('course_id', String(254), primary_key = True)
    school_id = Column('school_id', Integer, ForeignKey("schools.school_id"), nullable = False)
    department_id = Column('department_id', String(254), ForeignKey("departments.department_id"), nullable = False)
    department_specific_course_id = Column('department_specific_course_id', String(254), nullable = False)
    name = Column('name', String(254), nullable = False)
    context = Column('context', String(254), nullable = False)

    sections = relationship('Section', backref = backref('course', lazy='joined'), lazy='dynamic')
