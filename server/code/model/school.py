from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer

class School(Base, Ninja_Model_Mixin):
    __tablename__ = 'schools'
    school_id = Column('school_id', Integer, primary_key = True)
    school_name = Column('school_name', String(254) , nullable = False)
    current_term_code = Column('current_term_code', String(254), nullable = False)
    current_term_name = Column('current_term_name', String(254), nullable = False)

    def __init__(self, school_id, school_name, current_term_code, current_term_name):
        self.school_id = school_id
        self.school_name = school_name
        self.current_term_code = current_term_code
        self.current_term_name = current_term_name


