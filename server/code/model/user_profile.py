from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer, DateTime
from sqlalchemy.dialects import mysql

class UserProfile(Base, Ninja_Model_Mixin):
    __tablename__ = 'userprofile'
    
    phonenumber = Column('phonenumber', String(10), primary_key = True)
    credits = Column('credits', Integer, nullable = False)
    email = Column('email', String(254))
    first_target_timestamp = Column('first_target_timestamp', mysql.TIMESTAMP, nullable = True)
