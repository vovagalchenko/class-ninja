from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response

class list_auth_pitch(HTTP_Response_Builder):
    def do_controller_specific_work(self):
        return HTTP_Response('200 OK', {'auth_pitch' : 'Please register with Class Radar to start tracking classes you are interested in. You can target 3 classes for free after you register. We don\'t use your phone number for anything other than keeping track of your targets.'})
