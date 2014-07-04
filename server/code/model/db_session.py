from sqlalchemy import *
from sqlalchemy.orm import sessionmaker
from lib.cfg import CFG

class DB_Session_Factory(object):
    session = None

    @staticmethod
    def get_db_session():
        if DB_Session_Factory.session is None:
            db_engine = create_engine(CFG.get_instance().get('db', 'dsn'), echo=False)
            Session = sessionmaker(bind = db_engine)
            DB_Session_Factory.session = Session()
        return DB_Session_Factory.session

    @staticmethod
    def cleanup():
        if DB_Session_Factory.session is not None:
            DB_Session_Factory.session.close()
            DB_Session_Factory.session = None
