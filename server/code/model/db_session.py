from sqlalchemy import *
from sqlalchemy.orm import sessionmaker, scoped_session
from sqlalchemy.pool import QueuePool
from lib.cfg import CFG
import thread

class DB_Session_Factory(object):
    Session = None

    @staticmethod
    def get_db_session(debug=False):
        if DB_Session_Factory.Session is None:
            db_engine = create_engine(CFG.get_instance().get('db', 'dsn'), echo=debug, poolclass=QueuePool, pool_size = 5, pool_recycle = 3600, pool_reset_on_return = 'rollback', pool_timeout = 30)
            DB_Session_Factory.Session = scoped_session(sessionmaker(bind = db_engine))
        session = DB_Session_Factory.Session()
        return session

    @staticmethod
    def cleanup():
        if DB_Session_Factory.Session is not None:
            DB_Session_Factory.Session.remove()
