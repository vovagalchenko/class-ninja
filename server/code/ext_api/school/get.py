from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.school import School
from model.db_session import DB_Session_Factory


class get_school(HTTP_Response_Builder): 
    def do_controller_specific_work(self):
        db_session = DB_Session_Factory.get_db_session()
        school = db_session.query(School).get(self.resource_id)
        if school is None:
            raise API_Exception("404 Not Found", "Requested school_id was not found.")
        else:
          return HTTP_Response('200 OK', {'school' : school.for_api()})
