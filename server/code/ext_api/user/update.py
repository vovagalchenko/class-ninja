from model.db_session import DB_Session_Factory
from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from ext_api.parameter import Parameter, String_Parameter_Type
from model.user_model import User
from model.user_profile import UserProfile

from datetime import datetime, timedelta
import re
import uuid

class update_user(HTTP_Response_Builder): 
    confirmation_token = Parameter("confirmation_token", required = True, parameter_type = String_Parameter_Type)    

    def do_controller_specific_work(self):
        phonenumber_regex = re.compile(r"\d{10}")
        confirmation_token_regex = re.compile(r"\d{6}")
        phonenumber = self.resource_id
        result = phonenumber_regex.match(phonenumber)
        if result is None:
            raise API_Exception("400 Bad Request", "Invalid phone number")
            return

        result = confirmation_token_regex.match(self.confirmation_token)                
        if result is None:
            raise API_Exception("400 Bad Request", "Invalid confirmation token")
            return

        db_session = DB_Session_Factory.get_db_session()
        user = db_session.query(User).get(self.resource_id)
        if user is None:
            raise API_Exception("404 Not Found", "Entry does not exist in DB")
            return
        
        current_ts = datetime.now()
        
        if (current_ts > user.confirmation_deadline):
            raise API_Exception("403 Forbidden", "Confirmation token request came exceeded confirmation deadline. Request next confirmation token")
            return

       
        if (user.confirmation_token != self.confirmation_token):
            raise API_Exception("401 Unauthorized", "Wrong confirmation token")
            return
        
        # if all of above checks passed we have a valid phone number, confirmation token and confirmation done within
        # appropriate confirmation deadline. Go ahead, generate authorization token and give it back to user
        user.last_request_ts = current_ts

        # if user registers phone for the first time, generate token
        # and create credits
        if user.access_token is None:
            user.access_token = self.generate_access_token()
 
            userProfile = UserProfile()
            userProfile.phonenumber =  user.phonenumber
            # brand new user get 3 free credits
            userProfile.credits = 3
            userProfile.email = None

            db_session.add(userProfile)
        
        db_session.commit()
 
        return HTTP_Response('200 OK', {'access_token' : user.access_token})

    def generate_access_token(self):
        db_session = DB_Session_Factory.get_db_session() 
        access_token = uuid.uuid4()
        while True:
            users_with_generated_access_token = db_session.query(User).filter(User.access_token == access_token)
            if (len(users_with_generated_access_token.all()) == 0):
                return access_token 
            access_token = uuid.uuid4()
     
 
