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

class Ninja_Model_Mixin(object):
    def for_api(self):
        ret_value = {}
        for column_name in self.__mapper__.columns.keys():
            column_value = getattr(self, column_name)
            ret_value[column_name] = column_value
    
        return ret_value

