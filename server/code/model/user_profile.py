from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer, DateTime

class UserProfile(Base, Ninja_Model_Mixin):
    __tablename__ = 'userprofile'
    
    phonenumber = Column('phonenumber', String(10), primary_key = True)
    credits = Column('credits', Integer, nullable = False)
    email = Column('email', String(254))

