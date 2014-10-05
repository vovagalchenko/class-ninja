class API_Exception(Exception):
    message = "Unknown error"
    error_code = 500
    http_status_map = {
        400 : 'Bad Request',
        401 : 'Unauthorized',
        405 : 'Method Not Allowed',
        422 : 'Unprocessable Entity',
        500 : 'Server Error',
        502 : 'Bad Gateway'
    }

    def __init__(self, error_code, msg):
        super(API_Exception, self).__init__(msg)
        self.message = msg
        self.error_code = error_code
        
    def as_string(self):
        return self.message

    def get_http_status(self):
        return str(self.error_code) + ' ' + self.http_status_map.get(self.error_code, '')

    def get_error_code(self):
        return self.error_code

class Invalid_API_Call_Exception(API_Exception):
    def __init__(self, method, endpoint, msg):
        super(Invalid_API_Call_Exception, self).__init__(400, "Invalid API call {%s %s}: %s" % (method, endpoint, msg))

class Invalid_API_Method_Exception(Invalid_API_Call_Exception):
    def __init__(self, method, endpoint, msg):
        super(Invalid_API_Method_Exception, self).__init__(method, endpoint, msg)
        self.error_code = 405

class Authorization_Exception(API_Exception):
    def __init__(self, message):
        super(Authorization_Exception, self).__init__(401, message)

class Unprocessable_Entity_Exception(API_Exception):
    def __init__(self, message):
        super(Unprocessable_Entity_Exception, self).__init__(422, message)

class Bad_Gateway_Exception(API_Exception):
    def __init__(self, message):
        super(Bad_Gateway_Exception, self).__init__(502, message)
