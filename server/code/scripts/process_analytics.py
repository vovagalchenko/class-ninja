#!/usr/bin/python -u

CLIENT_LOG_ROOT = "/var/class_ninja/data/client_logs"

import sys, json, os, datetime, copy, codecs
from pytz import timezone

user_agent = os.environ["HTTP_USER_AGENT"]
user_agent_array = user_agent.split()
if len(user_agent_array) is not 2:
    sys.stderr.write("Invalid User-Agent for uploading analytics: " + user_agent)
    exit(0)
platform = user_agent_array[0]
install_id = user_agent_array[1]
if platform != "iOS":
    sys.stderr.write("Invalid platform for uploading analytics: " + platform)
    exit(0)
    
now = datetime.datetime.now()
today = now.date()
file_path = "%s/%s/%d/%d/%d/%s.%d%d%d%d" % (CLIENT_LOG_ROOT, platform, today.year, today.month, today.day, install_id, now.hour, now.minute, now.second, now.microsecond)
try:
    os.makedirs(os.path.dirname(file_path))
except OSError:
    # The directory is already created
    pass
    
with codecs.open(file_path, "w", encoding='utf-8') as f:
    http_body = sys.stdin.read()
    try:
        http_body_list = json.loads(http_body)
    except ValueError, e:
        sys.stderr.write("Unable to json decode body:\n\n\n" + http_body)
        sys.stderr.write(str(e))
        exit(1)
    assert isinstance(http_body_list, list), "The received analytics must be an array of event groups. Actually received: " + str(http_body_list)
    for event_group in http_body_list:
        events = event_group.pop('events', None)
        assert isinstance(events, list), "Each event group must contain a key 'events' with an array of events."
        for event in events:
            timestamp = event.pop('timestamp', None)
            assert isinstance(timestamp, (int, long, float, complex)), "Each event must contain a key 'timestamp' with a number indicating the time of when the event happened"
            time_of_event = datetime.datetime.fromtimestamp(timestamp, timezone("America/Los_Angeles"))
            event_name = event.pop('event_name', None)
            assert event_name is not None, "Each event must contain a value for key 'event_name' with a string indicating the name of the event"
            event_type = event.pop('event_type', None)
            assert event_type is not None, "Each event must contain a value for key 'event_type' indicating the name of the event type"
            event.update(event_group)
            user_timezone = event.get('user_timezone', None)
            if user_timezone is not None:
                event['user_time'] = datetime.datetime.fromtimestamp(timestamp, timezone(user_timezone)).isoformat()
            f.write("%s\tevent_name=\"%s\" event_type=\"%s\" %s\n" % (time_of_event.isoformat(), event_name, event_type, ' '.join(['%s="%s"' % (key, value) for (key, value) in event.items()])))

os.unlink(sys.argv[1])
exit(0)
