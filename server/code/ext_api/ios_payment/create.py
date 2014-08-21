from model.db_session import DB_Session_Factory
from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from ext_api.parameter import Parameter, String_Parameter_Type

from model.user_model import User
from model.user_profile import UserProfile

import requests
import json

class create_ios_payment(HTTP_Response_Builder): 
    appleReceiptData = Parameter("receipt_data", required = True, parameter_type = String_Parameter_Type) 
    
    def do_controller_specific_work(self):    
        if self.user is None:
            raise Authorization_Exception("You must be logged in to perform IAP.")

        db_session = DB_Session_Factory.get_db_session() 
        user_profile = db_session.query(UserProfile).get(self.user.phonenumber)

        if user_profile is None:
            raise API_Exception("500 Server Error", "User profile does not exist")
        
        url = "https://buy.itunes.apple.com/verifyReceipt"
        phone = self.user.phonenumber

        # use specific phone number for debugging
        if (phone == "4089126890"):
            url = "https://sandbox.itunes.apple.com/verifyReceipt"

        iapResponse = requests.post(url, json.dumps({'receipt-data': self.appleReceiptData}), verify=False)
        if iapResponse.status_code != 200:
            raise API_Exception("400 Bad Request", "Failed to connect to iTunes server")
  
        responseContentDict = json.loads(iapResponse.content)
        iapStatus = responseContentDict['status']
        
        if iapStatus != 0:
            raise API_Exception("400 Bad Request", {'iap_status' : str(iapStatus)})

        # if status == 0, we're cool, let's give a lot of credits to user profile
        # very large number
        user_profile.credits = 99999
        db_session.commit()
 
        return HTTP_Response('200 OK', {'credits' : user_profile.credits})
 
