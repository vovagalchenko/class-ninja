import sys, os

sys.path.append(os.path.dirname(__file__) + "/../")

from model.db_session import DB_Session_Factory
from model.user_model import User
from model.user_profile import UserProfile
from model.ios_inapp_receipts.py import iOSInAppReceipts
from sqlalchemy.schema import CreateTable

db_session = DB_Session_Factory.get_db_session()
db_session.execute(CreateTable(iOSInAppReceipts.__table__))
db_session.execute(CreateTable(UserProfile.__table__))
db_session.execute(CreateTable(User.__table__))

