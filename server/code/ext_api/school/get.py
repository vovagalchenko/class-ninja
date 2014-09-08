from ext_api.exceptions import API_Exception,Invalid_API_Call_Exception
from ext_api.http_response_builder import HTTP_Response_Builder, HTTP_Response
from model.school import School
from model.db_session import DB_Session_Factory
from model.department import Department
from model.course import Course
from ext_api.parameter import Parameter, String_Parameter_Type
import urllib
import re

class get_school(HTTP_Response_Builder): 
    search_query = Parameter("query", required = False, parameter_type = String_Parameter_Type)

    def do_controller_specific_work(self):
        if self.search_query is None:
            return self.departmentLookup()
        else:
            return self.search(self.search_query)

    def departmentLookup(self):
        db_session = DB_Session_Factory.get_db_session()
        department_ids = map(lambda row: row[0], db_session.query(Course.department_id).distinct().filter(Course.school_id == self.resource_id).all())
        departments = db_session.query(Department).filter(Department.department_id.in_(department_ids)).order_by(Department.name.asc()).all()
        return HTTP_Response('200 OK', {'school_departments' : departments})

    def search(self, requestString):
        unquoted_request = urllib.unquote(requestString)
        search_terms = re.split('\s+', unquoted_request)
        # sort search words by length and then reverse them, so that we have longest words on top
        search_terms.sort(key = len)
        search_terms.reverse()

        if len(search_terms) == 0:
            raise API_Exception("400 Bad Request", "Search string not supplied")

        if len(search_terms[0]) <= 2: 
            raise API_Exception("400 Bad Request", "At least one search string has to be more than 2 symbols")

        where_clause = self.form_where_clause_for_search_terms(search_terms)
        departments = self.search_for_departments(where_clause)
        courses = self.search_for_courses(where_clause)
        departments_of_courses = self.search_for_departments_of_courses(courses)
        
        return HTTP_Response('200 OK', {'searched_departments' : departments, 'searched_courses' : courses, 'searched_courses_departments' : departments_of_courses})

    def search_for_courses(self, whereClause):
        db_session = DB_Session_Factory.get_db_session()
        sqlQuery = "SELECT course_id from " + Course.__tablename__ + " " + whereClause + " LIMIT 20"
        course_ids = self.single_row_query(sqlQuery)
        if len(course_ids) == 0:
            return []
        courses = db_session.query(Course).filter(Course.course_id.in_(course_ids)).all()
        return courses

    def search_for_departments_of_courses(self, courses):
        db_session = DB_Session_Factory.get_db_session()
        department_ids_for_courses = map(lambda course: course.department_id, courses)
        return self.search_for_departments_by_dept_ids(department_ids_for_courses)

    def search_for_departments_by_dept_ids(self, department_ids): 
        db_session = DB_Session_Factory.get_db_session()
        if len(department_ids) == 0:
           return []
        
        departments = db_session.query(Department).filter(Department.department_id.in_(department_ids)).all()
        return departments

    def search_for_departments(self, whereClause):
        db_session = DB_Session_Factory.get_db_session()
        sqlQuery = "SELECT department_id from " + Department.__tablename__ + " "+ whereClause + " LIMIT 20"
        department_ids = self.single_row_query(sqlQuery)
        if len(department_ids) == 0:
            return []
       
        department_ids_with_active_courses = map(lambda row: row[0], db_session.query(Course.department_id).distinct().filter(Course.school_id == self.resource_id).all())
        #filter out department_ids that don't have any active courses
        department_ids = list(set(department_ids) & set(department_ids_with_active_courses))

        return self.search_for_departments_by_dept_ids(department_ids)

    def form_where_clause_for_search_terms(self, searchTerms):
        whereClause = "WHERE school_id=" + self.resource_id
        for term in searchTerms:
           whereClause = whereClause + " and " + self.like_clause_for_term(term)

        return whereClause
        
    def like_clause_for_term(self, term):
        likeClause = "'%" + term + "%'"
        result = "name LIKE " + likeClause
        return result

    def single_row_query(self, sqlQuery): 
        db_session = DB_Session_Factory.get_db_session()
        query_result = db_session.execute(sqlQuery)
        searched_department_ids = []
        for row in query_result:
            searched_department_ids.append(row[0])

        return searched_department_ids
