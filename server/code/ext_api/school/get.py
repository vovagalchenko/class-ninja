from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response

class get_school(HTTP_Response_Builder):

    
    def do_controller_specific_work(self):
        return HTTP_Response('200 OK', {'departments_list' : 'awesome departments %s' % (self.resource_id)})
