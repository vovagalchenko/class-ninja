from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer, DateTime, Boolean
from sqlalchemy.dialects import mysql

class UserProfile(Base, Ninja_Model_Mixin):
    __tablename__ = 'userprofile'
    
    phonenumber = Column('phonenumber', String(10), primary_key = True)
    credits = Column('credits', Integer, nullable = False)

    didPostOnFb = Column('didPostOnFb', Boolean, nullable = True)
    didPostOnTwitter = Column('didPostOnTwitter', Boolean, nullable = True)
    
    referred_by = Column('referred_by', String(254))

    email = Column('email', String(254))
    first_target_timestamp = Column('first_target_timestamp', mysql.TIMESTAMP, nullable = True)
