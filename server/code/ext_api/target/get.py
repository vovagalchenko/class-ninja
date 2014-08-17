from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.target import Target
from model.user_model import User
from model.db_session import DB_Session_Factory

class get_target(HTTP_Response_Builder): 
    def do_controller_specific_work(self):
        db_session = DB_Session_Factory.get_db_session()
        targets = db_session.query().filter(Target.user_phone_number == self.user.phonenumber).all()
        return HTTP_Response('200 OK', {'targets' : targets})
