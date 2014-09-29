class API_Exception(Exception):
    message = "Unknown error"
    http_status = "500 Server Error"

    def __init__(self, http_status, msg):
        super(API_Exception, self).__init__(msg)
        self.message = msg
        self.http_status = http_status
        
    def as_string(self):
        return self.message

    def get_http_status(self):
        return self.http_status

class Invalid_API_Call_Exception(API_Exception):
    def __init__(self, method, endpoint, msg):
        super(Invalid_API_Call_Exception, self).__init__("400 Bad Request", "Invalid API call {%s %s}: %s" % (method, endpoint, msg))

class Invalid_API_Method_Exception(Invalid_API_Call_Exception):
    def __init__(self, method, endpoint, msg):
        super(Invalid_API_Method_Exception, self).__init__(method, endpoint, msg)

    def get_http_status(self):
        return "405 Method Not Allowed"

class Authorization_Exception(API_Exception):
    def __init__(self, message):
        super(Authorization_Exception, self).__init__("401 Unauthorized", message)

class Unprocessable_Entity_Exception(API_Exception):
    def __init__(self, message):
        super(Unprocessable_Entity_Exception, self).__init__("422 Unprocessable Entity", message)

class Bad_Gateway_Exception(API_Exception):
    def __init__(self, message):
        super(Bad_Gateway_Exception, self).__init__("502 Bad Gateway", message)
