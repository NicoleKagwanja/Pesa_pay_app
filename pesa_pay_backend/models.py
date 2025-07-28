from sqlalchemy import Column, Date, Float, Integer, String
from database import Base

class Employee(Base):
    __tablename__ = "employees"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    phone = Column(String)
    gender = Column(String)
    department = Column(String)
    salary = Column(Float)
    bank_name = Column(String)
    account_number = Column(String)
    password = Column(String)

class OffWeekRequest(Base):
    __tablename__ = "off_week_requests"
    id = Column(Integer, primary_key=True, index=True)
    employee_email = Column(String, index=True)
    start_date = Column(Date)
    end_date = Column(Date)
    status = Column(String, default="pending")

class Attendance(Base):
    __tablename__ = "attendance"
    id = Column(Integer, primary_key=True, index=True)
    employee_email = Column(String, index=True)
    date = Column(Date)
    status = Column(String)