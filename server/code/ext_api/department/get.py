from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.department import Department
from model.db_session import DB_Session_Factory

class get_department(HTTP_Response_Builder):
    def do_controller_specific_work(self):  
        db_session = DB_Session_Factory.get_db_session()
        department = db_session.query(Department).get(self.resource_id)
        if department is None:
            raise API_Exception("404 Not Found", "Requested department_id not found.")
        else:         
            return HTTP_Response('200 OK', {'department' : department.for_api()})

