from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response

class list_sales_pitch(HTTP_Response_Builder):
    def do_controller_specific_work(self):
        return HTTP_Response('200 OK', {'sales_pitch' : 'It costs us real money to run this service for you. We hope you enjoy using it.\n\nFor just %@, you will be able to track ten more classes.'})
