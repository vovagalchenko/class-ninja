from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response

from lib.cfg import CFG

class list_auth_pitch(HTTP_Response_Builder):
    def do_controller_specific_work(self):
        cfg = CFG.get_instance()
        targets_for_signup = int(cfg.get('sales_pitch', 'targets_for_signup'))
        # if you're chaning number of free classes in auth pitch, also change sales_pitch and user/update.py
        auth_pitch = 'Please register with Class Radar to start tracking classes you are interested in.'
        auth_pitch = auth_pitch + ' You can target ' + str(targets_for_signup) + ' classes for free after you register.'
        auth_pitch = auth_pitch + ' We don\'t use your phone number for anything other than keeping track of your targets.'
        return HTTP_Response('200 OK', {'auth_pitch' : auth_pitch})
