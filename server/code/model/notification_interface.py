from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, ForeignKey, Integer
from model.user_profile import UserProfile

class Notification_Interface(Base, Ninja_Model_Mixin):
    __tablename__ = 'notification_interfaces'
    notification_interface_id = Column('notification_interface_id', Integer(11), primary_key = True)
    user_phone_number = Column('user_phone_number', String(254), ForeignKey('userprofile.phonenumber'), nullable = False)
    kind = Column('kind', String(254), nullable = False)
    notification_interface_key = Column('notification_interface_key', String(254), nullable = False)
    notification_interface_name = Column('notification_interface_name', String(254), nullable = False)
