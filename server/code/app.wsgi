from json import dumps
import sys
import re
import traceback
from urlparse import urlparse

def basic_application(environ, start_response):
    document_root = environ.get('CONTEXT_DOCUMENT_ROOT', '')
    if document_root not in sys.path:
        sys.path.insert(0, document_root)
    else:
        sys.path.insert(0, sys.path.pop(sys.path.index(document_root)))

    # Make the error log global
    import __builtin__
    __builtin__.error_log = environ['wsgi.errors']

    global ext_api
    import ext_api
    from ext_api.exceptions import API_Exception
    from ext_api.http_response_builder import HTTP_Response
    from model.db_session import DB_Session_Factory

    try:
        controller = get_controller(environ)
        response = controller.run()
    except API_Exception as e:
        response = HTTP_Response(e.get_http_status(), {'error' : e.as_string()})
    except Exception as e:
        traceback.print_exc(file=error_log)
        response = HTTP_Response("500 Server Error", {'error' : 'Unexpected backend issue'})
    finally:
        DB_Session_Factory.cleanup()

    start_response(response.get_status(), response.get_headers())
    return response.get_body_string()

def get_api_endpoint(env):
    request_uri = env.get('REQUEST_URI', '') 
    parsed_uri = urlparse(request_uri)
    path = parsed_uri.path
    match = re.match('\/api\/(.+)$', path);
    endpoint = None
    if match is not None:
        endpoint = match.group(1)
        if endpoint[-1] == '/':
            endpoint = endpoint[:-1]
    return endpoint

def get_controller(env):
    endpoint = get_api_endpoint(env)
    http_method = env['REQUEST_METHOD'].upper()
    if http_method not in ("GET", "POST", "DELETE"):
        raise ext_api.exceptions.Invalid_API_Method_Exception(http_method, endpoint, "At this point only GET, POST, DELETE HTTP methods are part of the API")
    content_length = int(env.get('CONTENT_LENGTH', 0))
    if content_length > 0 and http_method == 'GET':
        raise Invalid_API_Call_Exception(http_method, endpoint, "This API doesn't accept HTTP body for GET requests.")
    controller = None
    if endpoint is not None:
        endpoint = endpoint.lower()
        endpoint_list = endpoint.split('/')
        if len(endpoint_list) not in (1, 2):
            raise ext_api.exceptions.Invalid_API_Call_Exception(http_method, endpoint, "Endpoints must look like {<resource>} or {<resource>/<id>}")

        resource = endpoint_list[0]
        try:
            resource_module_name = 'ext_api.' + resource
            resource_module = __import__(resource_module_name)
        except ImportError as e:
            traceback.print_exc(file=error_log)
            raise ext_api.exceptions.Invalid_API_Call_Exception(http_method, endpoint, "Invalid resource <%s>" % (resource))

        resource_id = endpoint_list[1] if len(endpoint_list) is 2 else None

        action = "get"
        if resource_id is None:
            if http_method == "GET":
                action = "list"
            elif http_method == "POST":
                action = "create"
            elif http_method == "DELETE":
                raise Invalid_API_Call_Exception(http_method, endpoint, "This API requires resource ID to delete.")
        else:
            if http_method == "GET":
                action = "get"
            elif http_method == "POST":
                action = "update"
            elif http_method == "DELETE":
                action = "delete"
        class_name = action + '_' + resource
        try:
            action_module = __import__(resource_module_name + '.' + action, fromlist = [class_name])
        except ImportError as e:
            traceback.print_exc(file=error_log)
            raise ext_api.exceptions.Invalid_API_Call_Exception(http_method, endpoint, "%s operation is not implemented" % (class_name))
        klass = getattr(action_module, class_name)
        controller = klass(env, resource_id)
    else:
        raise ext_api.exceptions.Invalid_API_Call_Exception(http_method, endpoint, "Please specify what API call you would like to make.")
    return controller



from StringIO import StringIO
import zlib

class UnzipRequestMiddleware(object):
    """A middleware that unzips POSTed data.
 
    For this middleware to kick in, the client must provide a value
    for the ``Content-Encoding`` header. The only accepted value is
    ``gzip``. Any other value is ignored.
    """
 
    def __init__(self, app):
        self.app = app
 
    def __call__(self, environ, start_response):
        encoding = environ.get('HTTP_CONTENT_ENCODING')
        if encoding == 'gzip':
            data = environ['wsgi.input'].read(int(environ.get('CONTENT_LENGTH', '0')))
            try:
                uncompressed = zlib.decompress(data, zlib.MAX_WBITS|16)
                environ['wsgi.input'] = StringIO(uncompressed)
                environ['CONTENT_LENGTH'] = len(uncompressed)
            except zlib.error as e:
                print >> environ['wsgi.errors'], "Could not decompress request data."
                print >> environ['wsgi.errors'], str(e)
                environ['wsgi.input'] = StringIO(data)
        return self.app(environ, start_response)

application = UnzipRequestMiddleware(basic_application)
