from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response

class list_school(HTTP_Response_Builder):

    def do_controller_specific_work(self):
        return HTTP_Response('200 OK', {'test_response' : 'blahblah'})
