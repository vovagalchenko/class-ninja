from json import dumps, loads
from ext_api.exceptions import *
from ext_api.parameter import Parameter, Invalid_Parameter_Exception
from urlparse import parse_qsl
from re import subn
from model.db_session import DB_Session_Factory
from model.user_model import User
from model.user_profile import UserProfile
from model.base import Ninja_Model_Mixin
from datetime import datetime, date
from lib.time_utils import dt_to_timestamp
import requests

class HTTP_Response_Builder(object):
    warnings = []
    resource_id = None
    request_headers = {}
    user = None
    user_profile = None
    handles_http_body_processing = False
    body_stream = None
    content_length = None
    http_user_agent = None

    def __init__(self, env, resource_id):
        query_string = env.get('QUERY_STRING', '')
        self.http_user_agent = env.get('HTTP_USER_AGENT', None)
        self.body_stream = env.get('wsgi.input', None)
        self.content_length = int(env.get('CONTENT_LENGTH', 0))
        self.request_headers = {}
        for key in env:
            (header_name, num_subs) = subn(r'^HTTP_', '', key)
            if num_subs is 1:
                self.request_headers[header_name] = env[key]

        self.warnings = []
        self.resource_id = resource_id
        passed_in_param_dict= {}
        if self.content_length > 0 and not self.handles_http_body_processing:
            body_str = self.body_stream.read(self.content_length)
            try:
                passed_in_param_dict = loads(body_str)
                if not isinstance(passed_in_param_dict, dict):
                    raise ValueError("The HTTP body must be a dictionary")
            except ValueError as e:
                error_log.write(e.args[0])
                raise API_Exception(400, "The HTTP body must be a JSON-encoded dictionary.")
        query_param_list = {}
        if query_string:
            try:
                query_param_list = parse_qsl(query_string, True, True)
            except ValueError as e:
                raise API_Exception(400, "The query string must be URL encoded.")
        for k,v in query_param_list:
            if k in passed_in_param_dict:
                raise Invalid_Parameter_Exception(k, "This parameter is given twice. Between the query string and the HTTP body, every parameter can only be specified once.")
            passed_in_param_dict[k] = v
        for param_name in dir(self):
            param_definition = getattr(self, param_name)
            if not isinstance(param_definition, Parameter):
                continue
            param_value = param_definition.get_value(passed_in_param_dict.get(param_definition.name, None))
            passed_in_param_dict.pop(param_definition.name, None)
            setattr(self, param_name, param_value)
        self.authenticate()

    def authenticate(self):
        auth_header = self.request_headers.get('AUTHORIZATION', None)
        if auth_header is not None:
            db_session = DB_Session_Factory.get_db_session() 
            results = db_session.query(User, UserProfile).filter(User.phonenumber == UserProfile.phonenumber).filter(User.access_token == auth_header).all()
            if len(results) > 1:
                raise API_Exception(500, "This access token is being used by multiple users.")
            elif len(results) == 1:
                self.user = results[0][0]
                self.user_profile = results[0][1]

    def finalize_http_response(self, http_response):
        if self.warnings:
            http_response.add_to_body('warnings', self.warnings)
        if self.user_profile is not None:
            http_response.add_to_body('credits', self.user_profile.credits)
            http_response.add_to_body('user_profile', self.user_profile)

        return http_response

    def do_controller_specific_work(self):
        return HTTP_Response("200 OK", {"ho lee" : "fuk"})

    def run(self):
        http_response = self.do_controller_specific_work()
        return self.finalize_http_response(http_response)


def serialize(obj):
    serialized_obj = "<UNSERIALIZABLE_OBJECT>"
    if isinstance(obj, datetime) or isinstance(obj, date):
        serialized_obj = dt_to_timestamp(obj)
    elif isinstance(obj, Ninja_Model_Mixin):
        serialized_obj = obj.for_api()
    return serialized_obj

class HTTP_Response(object):
    
    def __init__(self, status_string, json_serializable_body):
        self.status = status_string
        self.body = json_serializable_body
        self.serialized_body_cache = None
        self.headers = [
            ('Content-Type' , 'application/json')
        ]

    def add_to_body(self, key, value):
        self.body[key] = value
        self.serialized_body_cache = None

    def get_status(self):
        return self.status
    
    def get_body_string(self):
        if self.serialized_body_cache is None:
            if self.body is None:
                self.serialized_body_cache = ''
            else:
                dthandler = lambda obj: serialize(obj)
                self.serialized_body_cache = dumps(self.body, default = dthandler)
        return self.serialized_body_cache
    
    def get_headers(self):
        headers = self.headers
        headers.append(('Content-Length', str(len(self.get_body_string()))))
        return headers
