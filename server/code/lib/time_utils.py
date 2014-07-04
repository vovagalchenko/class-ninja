from datetime import datetime
from pytz import timezone
from calendar import timegm

def timestamp_to_dt(raw_value):
    naive_dt = datetime.fromtimestamp(float(raw_value))
    server_tz = timezone('America/Los_Angeles')
    aware_dt = server_tz.localize(naive_dt)
    return aware_dt

def dt_to_timestamp(dt):
    return timegm(dt.utctimetuple())
