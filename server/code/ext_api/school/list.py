from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.school import School
from model.db_session import DB_Session_Factory

class list_school(HTTP_Response_Builder):
    def do_controller_specific_work(self):
        db_session = DB_Session_Factory.get_db_session()
        schools = db_session.query(School).all()
        if schools is not None:
            schoolCollection = []
            for school in schools:
                schoolJSON = school.for_api()
                schoolCollection.append(schoolJSON)
            return HTTP_Response('200 OK', {'schools' : schoolCollection})
        else:
            return HTTP_Response('404 Not found', 'Failed to list schools.')
