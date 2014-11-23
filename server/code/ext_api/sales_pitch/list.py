from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response

class list_sales_pitch(HTTP_Response_Builder):
    def do_controller_specific_work(self):
        sales_pitch = {}
        sales_pitch['sales_pitch'] = 'It costs us real money to run this service. We hope you enjoy using it.\n\nFor just %@, you will be able to track another ten classes.'
        sales_pitch['short_sales_pitch'] = 'Or track 10 more classes for just %@.'
        sales_pitch['sharing_pitch'] = 'Track another %@ for free by helping us spread the word.'
        sales_pitch['targets_for_purchase'] = 10
        sales_pitch['targets_for_sharing'] = 10
        sales_pitch['signup_reminder'] = 'We let you track the first %@ classes for free.'
        #if you're changing targest for signup, also change auth_pitch and user/update
        sales_pitch['targets_for_signup'] = 3
        return HTTP_Response('200 OK', sales_pitch)
