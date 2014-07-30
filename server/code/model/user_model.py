from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer, DateTime
from sqlalchemy.orm import relationship, backref
from model.target import Target

class User(Base, Ninja_Model_Mixin):
    __tablename__ = 'authentication'
    
    phonenumber = Column('phonenumber', String(10), primary_key = True)
    device_vendor_id = Column('device_vendor_id', String(254), nullable = False)
    access_token = Column('access_token', String(36))
    confirmation_token = Column('confirmation_token', String(6), nullable = False)
    confirmation_deadline = Column('confirmation_deadline', DateTime, nullable = False)
    last_request_ts = Column('last_request_ts', DateTime, nullable = False)

    targets = relationship("Target", backref = "user")
