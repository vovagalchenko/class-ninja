from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, Enum, ForeignKey, Integer, TEXT

class Config(Base, Ninja_Model_Mixin):
    __tablename__ = 'configuration'
    config_id = Column('config_id', String(254), primary_key = True)
    account = Column('account', String(254), nullable = False)
    auth_token = Column('auth_token', String(254), nullable = False)
    from_phone = Column('from_phone', String(12), nullable = False)
