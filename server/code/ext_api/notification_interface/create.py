from model.db_session import DB_Session_Factory
from ext_api.exceptions import API_Exception, Authorization_Exception, Unprocessable_Entity_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from ext_api.parameter import Parameter, String_Parameter_Type
from model.notification_interface import Notification_Interface

class create_notification_interface(HTTP_Response_Builder): 
    kind = Parameter("kind", required = True, parameter_type = String_Parameter_Type)    
    notification_interface_key = Parameter("notification_interface_key", required = True, parameter_type = String_Parameter_Type)    
    notification_interface_name = Parameter("notification_interface_name", required = True, parameter_type = String_Parameter_Type)    
    
    def do_controller_specific_work(self):    
        if self.user is None:
            raise Authorization_Exception("You must be logged in to create a notification interface.")

        if self.kind != 'iOS' and self.kind != 'iOS-sandbox':
            raise Unprocessable_Entity_Exception("Only 'iOS' kind of notification interfaces are currently supported. Provided: " + str(self.kind))

        db_session = DB_Session_Factory.get_db_session() 
        notification_interface = db_session.query(Notification_Interface).filter(Notification_Interface.user_phone_number == self.user.phonenumber, Notification_Interface.kind == self.kind, Notification_Interface.notification_interface_key == self.notification_interface_key).first()
        if notification_interface is None:
            notification_interface = Notification_Interface()
            notification_interface.user_phone_number = self.user.phonenumber
            notification_interface.kind = self.kind
            notification_interface.notification_interface_key = self.notification_interface_key
        notification_interface.notification_interface_name = self.notification_interface_name
        db_session.add(notification_interface)
        db_session.flush()
        res = notification_interface.for_api()
        db_session.commit()
 
        return HTTP_Response('200 Success', {'notification_interface' : res})
 
