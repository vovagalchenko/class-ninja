from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, ForeignKey, Integer
from sqlalchemy.orm import relationship, backref
from model.event import Event


class Target(Base, Ninja_Model_Mixin):
    __tablename__ = 'targets'
    target_id = Column('target_id', Integer, primary_key = True)
    event_id = Column('event_id', String(254), ForeignKey("events.event_id"), nullable = False)
    user_phone_number = Column('user_phone_number', String(254), ForeignKey("authentication.phonenumber"), nullable = False)

    event = relationship("Event", backref = "target")

    def __init__(self, taget_id, event_id, user_phone_number):
        self.target_id = target_id
        self.event_id = event_id
        self.user_phone_number = user_phone_number
