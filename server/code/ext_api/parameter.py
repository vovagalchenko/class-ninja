import base64
import xml.etree.ElementTree as ET
from ext_api.exceptions import API_Exception
from json import loads
from lib.time_utils import timestamp_to_dt

class Parameter_Type(object):
    @classmethod
    def get_value_from_raw(cls, raw_value):
        raise NotImplementedError, 'Must override get_value_from_raw'

class Integer_Parameter_Type(Parameter_Type):
    @classmethod
    def get_value_from_raw(cls, raw_value):
        return int(raw_value)

class String_Parameter_Type(Parameter_Type):
    @classmethod
    def get_value_from_raw(cls, raw_value):
        return raw_value

class Base_64_Encoded_String_Parameter_Type(Parameter_Type):
    @classmethod
    def get_value_from_raw(cls, raw_value):
        return base64.b64decode(raw_value)

class Base_64_Encoded_XML_Parameter_Type(Base_64_Encoded_String_Parameter_Type):
    @classmethod
    def get_value_from_raw(cls, raw_value):
        decoded_string = super(Base_64_Encoded_XML_Parameter_Type, cls).get_value_from_raw(raw_value)
        return ET.fromstring(decoded_string)

class Date_Time_Parameter_Type(Parameter_Type):
    @classmethod
    def get_value_from_raw(cls, raw_value):
        return timestamp_to_dt(raw_value)

class Boolean_Parameter_Type(Parameter_Type):
    @classmethod
    def get_value_from_raw(cls, raw_value):
        ret_value = None
        if raw_value == 'true':
            ret_value = True
        elif raw_value == 'false':
            ret_value = False
        else:
            raise ValueError("Only \"true\" and \"false\" are acceptable values for a boolean.")
        return ret_value

class Array_Parameter_Type(Parameter_Type):
    @classmethod
    def get_value_from_raw(cls, raw_array_value):
        if not isinstance(raw_array_value, list):
            raise ValueError("This argument is expected to be a list.")
        return raw_array_value
            

class Parameter(object):
    name = None
    default = None
    required = False
    parameter_type = Parameter_Type
    
    def __init__(self, name, default = None, required = True, parameter_type = String_Parameter_Type):
        self.name = name
        if self.name is None:
            raise ValueError, "Must pass in name when creating a parameter definition"
        self.default = default
        self.required = required
        self.parameter_type = parameter_type

    def get_value(self, passed_in_value):
        param_value = self.default
        if passed_in_value is not None:
            try:
                param_value = self.parameter_type.get_value_from_raw(passed_in_value)
            except ValueError as e:
                raise Invalid_Parameter_Exception(self.name, e.args[0])
        if self.required is True and param_value is None:
            raise Invalid_Parameter_Exception(self.name, "this parameter is required.")
        return param_value

class Invalid_Parameter_Exception(API_Exception):
    def __init__(self, param_name, msg):
        API_Exception.__init__(self, "400 Bad Request", "Parameter <%s>: %s" % (param_name, msg))
