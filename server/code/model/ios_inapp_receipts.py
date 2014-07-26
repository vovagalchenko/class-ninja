from base import Base, Ninja_Model_Mixin
from sqlalchemy import Column, String, ForeignKey, Integer, LargeBinary

class iOSInAppReceipts(Base, Ninja_Model_Mixin):
    __tablename__ = 'iosinappreceipts'    
    phonenumber = Column('phonenumber', String(10), primary_key = True)
    device_vendor_id = Column('receipt', LargeBinary, nullable = False)

