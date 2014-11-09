from model.db_session import DB_Session_Factory
from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from ext_api.parameter import Parameter, Boolean_Parameter_Type
from model.user_model import User
from model.user_profile import UserProfile

import requests
import json

class edit_user_profile(HTTP_Response_Builder): 
    didPostOnFb = Parameter("didPostOnFb", required = False, parameter_type = Boolean_Parameter_Type) 
    didPostOnTwitter = Parameter("didPostOnTwitter", required = False, parameter_type = Boolean_Parameter_Type) 
    
    def do_controller_specific_work(self):    
        if self.user is None:
            raise Authorization_Exception("You must be logged in to perform IAP.")

        if self.didPostOnFb == False and self.didPostOnTwitter == False:
            raise API_Exception("406 Not Acceptable", "Provided argument are not valid to change user profile")
            
        db_session = DB_Session_Factory.get_db_session() 
        self.user_profile = db_session.query(UserProfile).get(self.user.phonenumber)

        if self.user_profile is None:
            raise API_Exception("500 Server Error", "User profile does not exist")
       
        if self.didPostOnFb == True and self.user_profile.didPostOnFb == False:
            self.user_profile.didPostOnFb = True
            self.user_profile.credits += 3

        if self.didPostOnTwitter == True and self.user_profile.didPostOnTwitter == False:
            self.user_profile.didPostOnTwitter = True
            self.user_profile.credits += 3

        db_session.commit()
 
        return HTTP_Response('200 OK', {'credits' : self.user_profile.credits})
 
