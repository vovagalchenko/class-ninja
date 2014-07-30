from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.course import Course
from model.db_session import DB_Session_Factory
from model.department import Department

class get_department(HTTP_Response_Builder): 
    def do_controller_specific_work(self):
        db_session = DB_Session_Factory.get_db_session()
        courses = db_session.query(Course).filter(Course.department_id == self.resource_id).all()
        return HTTP_Response('200 OK', {'department_courses' : courses})
