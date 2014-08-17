from ext_api.exceptions import Authorization_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.db_session import DB_Session_Factory
from model.target import Target
from model.course import Course
from model.section import Section
from itertools import groupby

class list_target(HTTP_Response_Builder):
    def do_controller_specific_work(self):
        if self.user is None:
            raise Authorization_Exception("You must be logged in to list your targets.")
        events = map(lambda target: target.event, self.user.targets)
        events_by_section_id = dict((k, list(g)) for k, g in groupby(events, lambda event: event.section_id))
        db_session = DB_Session_Factory.get_db_session()
        sections = db_session.query(Section).filter(Section.section_id.in_(events_by_section_id.keys())).all()
        sections_by_course_id = dict((k, list(g)) for k, g in groupby(sections, lambda section: section.course_id))
        courses = db_session.query(Course).filter(Course.course_id.in_(sections_by_course_id.keys())).all()
        response = []
        for course in courses:
            course_dict = course.for_api()
            sections_list = []
            for section in sections_by_course_id.get(course.course_id):
                section_dict = section.for_api()
                section_dict['events'] = list(events_by_section_id[section.section_id])
                sections_list.append(section_dict)
            course_dict['course_sections'] = sections_list
            response.append(course_dict)
        return HTTP_Response('200 OK', {'targets' : response})