from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.db_session import DB_Session_Factory
from model.event import Event

class get_department(HTTP_Response_Builder): 
    def do_controller_specific_work(self):
        db_session = DB_Session_Factory.get_db_session()
        events = db_session.query(Event).filter(Event.session_id == self.resource_id)
        if events is None:
            raise API_Exception("404 Not Found", "Requested session_id was not found.")
        else:
            eventsCollection = []
            for event in events:
                eventsCollection.append(event.for_api())

            return HTTP_Response('200 OK', {'session_events' : eventsCollection})
