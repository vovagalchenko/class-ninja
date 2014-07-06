from ext_api.exceptions import API_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.db_session import DB_Session_Factory
from model.section import Section
from model.event import Event

class get_course(HTTP_Response_Builder): 
    def do_controller_specific_work(self):
        db_session = DB_Session_Factory.get_db_session()
        sections = db_session.query(Section).filter(Section.course_id == self.resource_id)
        if sections is None:
            raise API_Exception("404 Not Found", "Requested course_id was not found.")
        else:
            sectionsCollection = []
            for section in sections:
                sectionEvents = self.listEventsForSection(section.section_id)
                sectionInfo = section.for_api()
                sectionInfo['events'] = sectionEvents                
                sectionsCollection.append(sectionInfo)

            return HTTP_Response('200 OK', {'course_sections' : sectionsCollection})


    def listEventsForSection(self, sectionId): 
        db_session = DB_Session_Factory.get_db_session()
        events = db_session.query(Event).filter(Event.section_id == sectionId)
        eventsCollection = []
        for event in events:
            eventsCollection.append(event.for_api())

        return eventsCollection
