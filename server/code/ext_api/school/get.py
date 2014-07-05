from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.school import School
from model.db_session import DB_Session_Factory
from model.department import Department

class get_school(HTTP_Response_Builder): 
    def do_controller_specific_work(self):
        db_session = DB_Session_Factory.get_db_session()
        departments = db_session.query(Department).filter(Department.school_id == self.resource_id)
        if departments is None:
            raise API_Exception("404 Not Found", "Requested school_id was not found.")
        else:
            departmentCollection = []
            for department in departments:
                departmentCollection.append(department.for_api())

            return HTTP_Response('200 OK', {'school_departments' : departmentCollection})
