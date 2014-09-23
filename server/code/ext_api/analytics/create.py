from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
import subprocess, sys, os

class create_analytics(HTTP_Response_Builder):
    handles_http_body_processing = True

    def run(self):
        tmp_dir_name = "/tmp/class-ninja"
        if not os.path.exists(tmp_dir_name):
            os.makedirs(tmp_dir_name)
        error_log_path = tmp_dir_name + "/error_log_" + str(os.getpid())
        error_log_file = open(error_log_path, 'w')
        analytics_body = os.tmpfile()
        analytics_body.write(self.body_stream.read(self.content_length))
        analytics_body.seek(0)
        self.body_stream.close()
        this_dir = os.path.dirname(os.path.realpath(__file__))
        process_analytics_env = os.environ.copy()
        process_analytics_env['HTTP_USER_AGENT'] = self.http_user_agent
        p = subprocess.Popen([this_dir + '/../../scripts/process_analytics.py', error_log_path], stdout = error_log_file, stderr = error_log_file, stdin = analytics_body, env = process_analytics_env, close_fds = True)
        return HTTP_Response('204 No Content', None)
