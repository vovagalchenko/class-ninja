from model.db_session import DB_Session_Factory
from ext_api.exceptions import Bad_Gateway_Exception, API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from ext_api.parameter import Parameter, String_Parameter_Type

from model.user_model import User
from model.user_profile import UserProfile
from lib.cfg import CFG


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
            raise API_Exception(500, "User profile does not exist")
        
        # This throws if the check fails.
        self.checkVerificationService()
        # The check succeeded. Let's give a lot of credits to user profile.
        cfg = CFG.get_instance()
        targets_for_purchase = int(cfg.get('sales_pitch', 'targets_for_purchase'))
        user_profile.credits += targets_for_purchase
        db_session.commit()
        return HTTP_Response('200 OK', {'credits' : user_profile.credits})

    def checkVerificationService(self, passedInUrl = None):
        urlToUse = "https://buy.itunes.apple.com/verifyReceipt" if passedInUrl is None else passedInUrl
        iapResponse = requests.post(urlToUse, json.dumps({'receipt-data': self.appleReceiptData}), verify=False)
        if iapResponse.status_code != 200:
            raise Bad_Gateway_Exception("Failed to connect to iTunes server")
        iapResponseJson = iapResponse.json()
        status = iapResponseJson['status']
        if passedInUrl is None and status == 21007:
            self.checkVerificationService("https://sandbox.itunes.apple.com/verifyReceipt")
        elif status != 0:
            raise API_Exception(400, {'iap_status' : str(iapResponseJson)})
        
