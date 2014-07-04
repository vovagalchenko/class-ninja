from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, func, Integer, text
from sqlalchemy.types import DateTime, TypeDecorator
from datetime import datetime
from pytz import utc, timezone

Base = declarative_base()
la_timezone = timezone('America/Los_Angeles')

class UTCDateTime(TypeDecorator):
    
    impl = DateTime

    def process_result_value(self, value, engine):
        if value is not None:
            tz_aware_value = la_timezone.localize(value)
            return tz_aware_value

class Mafia_Model_Mixin(object):
    __table_args__ = {'mysql_engine' : 'InnoDB'}

    created = Column(UTCDateTime(True), nullable = False, server_default = func.current_timestamp())
    updated = Column(UTCDateTime(True), nullable = False, server_default = func.current_timestamp(), onupdate = func.current_timestamp())
    version = Column('version', Integer, nullable = False, server_default = text('0'), onupdate = text('version + 1'))

    # Below is a hack to make sure the mixin columns are added to the end of the actual model columns
    version._creation_order = 9997
    updated._creation_order = 9998
    created._creation_order = 9999

    def for_api(self):
        ret_value = {}
        for column_name in self.__mapper__.columns.keys():
            column_value = getattr(self, column_name)
            ret_value[column_name] = column_value
        return ret_value


