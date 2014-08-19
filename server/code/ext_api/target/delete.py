from model.db_session import DB_Session_Factory
from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.target import Target


class delete_target(HTTP_Response_Builder): 
    def do_controller_specific_work(self):
        if self.user is None:
            raise Authorization_Exception("You must be logged in to delete your targets.")
        
        target_id = self.resource_id

        db_session = DB_Session_Factory.get_db_session()
        target = db_session.query(Target).get(self.resource_id)
        if target is None:
            raise API_Exception("404 Not Found", "Entry does not exist in DB")
        
        if target.user_phone_number == self.user.phonenumber:        
            db_session.delete(target)
            db_session.commit()
            return HTTP_Response('200 OK', {'removed_target_id' : self.resource_id})
        else:
            raise Authorization_Exception("You can only delete targets associated with your account.")
 
