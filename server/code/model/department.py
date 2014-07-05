from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer

class Department(Base, Ninja_Model_Mixin):
    __tablename__ = 'departments'
    department_id = Column('department_id', String(254), primary_key = True)
    school_id = Column('school_id', Integer, ForeignKey("schools.school_id"), nullable = False)
    school_specific_id = Column('school_specific_id', String(254), nullable = False)
    name = Column('name', String(254), nullable = False)
