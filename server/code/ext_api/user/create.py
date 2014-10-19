from model.db_session import DB_Session_Factory
from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from ext_api.parameter import Parameter, String_Parameter_Type
from model.user_model import User
from lib.cfg import CFG
from random import randint
from twilio.rest import TwilioRestClient

from datetime import datetime, timedelta
import re

class create_user(HTTP_Response_Builder): 
    phonenumber = Parameter("phone", required = True, parameter_type = String_Parameter_Type)
    device_vendor_id = Parameter("device_vendor_id", required = False, parameter_type = String_Parameter_Type)
    
    def do_controller_specific_work(self):
        phonenumber_regex = re.compile(r"\d{10}")
        result = phonenumber_regex.match(self.phonenumber)
        if result is None:
            raise API_Exception(400, "Invalid phone number")
        else:
            db_session = DB_Session_Factory.get_db_session()
            cfg = CFG.get_instance()
            if self.phonenumber != str(cfg.get('apple_tester', 'phone_number')):
                user = db_session.query(User).get(self.phonenumber)
                current_ts = datetime.now()
                if user is None:
                    user = User()
                    user.phonenumber = self.phonenumber
                    user.device_vendor_id = self.device_vendor_id
                    user.access_token = None
                    user.confirmation_token = self.generate_confirmation_token()
                    user.confirmation_deadline = current_ts + timedelta(minutes = 5)
                    user.last_request_ts = current_ts
                    db_session.add(user)
                    db_session.commit()
                else:
                    user.confirmation_token = self.generate_confirmation_token()
                    user.confirmation_deadline = current_ts + timedelta(minutes = 5)
                    user.last_request_ts = current_ts
               
                    db_session.add(user)
                    db_session.commit()
            
                message = "Your code is " + user.confirmation_token
                self.send_code_to_phone(code_message=message, to_number=user.phonenumber) 
            return HTTP_Response('200 OK', {'status' : 'SMS request sent'})

    def generate_confirmation_token(self):
        return str(randint(100000, 999999))

    def send_code_to_phone(self, code_message, to_number):
        cfg = CFG.get_instance()
        client = TwilioRestClient(cfg.get('twilio', 'account'), cfg.get('twilio', 'auth_token'))
        client.sms.messages.create(to=to_number,from_=cfg.get('twilio', 'from_phone'),body=code_message)
    
     
