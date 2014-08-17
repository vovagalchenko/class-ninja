from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.school import School
from model.db_session import DB_Session_Factory
from model.department import Department
from model.course import Course

class get_school(HTTP_Response_Builder): 
    def do_controller_specific_work(self):
        db_session = DB_Session_Factory.get_db_session()
        department_ids = map(lambda row: row[0], db_session.query(Course.department_id).distinct().filter(Course.school_id == self.resource_id).all())
        departments = db_session.query(Department).filter(Department.department_id.in_(department_ids)).order_by(Department.name.asc()).all()
        return HTTP_Response('200 OK', {'school_departments' : departments})
