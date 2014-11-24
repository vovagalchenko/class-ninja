from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response

from lib.cfg import CFG

class list_sales_pitch(HTTP_Response_Builder):
    def do_controller_specific_work(self):
        sales_pitch = {}
        sales_pitch['sales_pitch'] = 'It costs us real money to run this service. We hope you enjoy using it.\n\nFor just %@, you will be able to track another ten classes.'
        sales_pitch['sharing_pitch'] = 'Track another %@ for free by helping us spread the word.'
        sales_pitch['signup_reminder'] = 'We let you track the first %@ classes for free.'

        cfg = CFG.get_instance()        
        sales_pitch['targets_for_purchase'] = int(cfg.get('sales_pitch', 'targets_for_purchase'))
        sales_pitch['targets_for_sharing'] = int(cfg.get('sales_pitch', 'targets_for_sharing'))
        sales_pitch['targets_for_signup'] = int(cfg.get('sales_pitch', 'targets_for_signup'))

        sales_pitch['short_sales_pitch'] = 'Or track ' + str(sales_pitch['targets_for_purchase'])  + ' more classes for just %@.'
    
        return HTTP_Response('200 OK', sales_pitch)
