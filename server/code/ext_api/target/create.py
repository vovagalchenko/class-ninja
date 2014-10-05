from model.db_session import DB_Session_Factory
from ext_api.exceptions import API_Exception, Authorization_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from ext_api.parameter import Parameter, Array_Parameter_Type
from model.user_model import User
from model.user_profile import UserProfile
from model.target import Target

from datetime import datetime
import re
import uuid

class create_target(HTTP_Response_Builder): 
    event_ids = Parameter("event_ids", required = True, parameter_type = Array_Parameter_Type)    
    
    def do_controller_specific_work(self):    
        if self.user is None:
            raise Authorization_Exception("You must be logged in to list your targets.")

        db_session = DB_Session_Factory.get_db_session() 
        user_profile = db_session.query(UserProfile).get(self.user.phonenumber)

        if user_profile is None:
            raise API_Exception("500 Server Error", "User profile does not exist")
        
        creditsWillConsume = len(self.event_ids)
        
        if user_profile.credits < creditsWillConsume:
            creditsRequired = creditsWillConsume - user_profile.credits
            raise API_Exception("402 Payment Required", {'credits_required' : creditsRequired})

        for event_id in self.event_ids:
            target = Target()
            target.event_id = event_id
            target.user_phone_number = self.user.phonenumber
            db_session.add(target)

        user_profile.credits = user_profile.credits - creditsWillConsume
        user_alert_dict = None
        if user_profile.first_target_timestamp is None:
            user_profile.first_target_timestamp = datetime.now()
            user_alert_dict = {
                'title' : 'Congratulations!',
                'msg'   : "You've set up your first tracked class. Whenever your tracked classes change enrollment status to 'Open' or 'Waitlist' we will send you push notifications immediately."
            }
        db_session.commit()
 
        return HTTP_Response('200 OK', {'credits' : user_profile.credits, 'user_msg' : user_alert_dict})
 
