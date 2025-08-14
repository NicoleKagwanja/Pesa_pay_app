from datetime import datetime
from sqlalchemy import Boolean, Column, Date, DateTime, Enum, Float, Integer, String
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
    is_admin = Column(Boolean, default=False)

class OffWeekRequest(Base):
    __tablename__ = "off_week_requests"

    id = Column(Integer, primary_key=True, index=True)
    employee_email = Column(String, nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    reason = Column(String, nullable=False)
    status = Column(Enum("pending", "approved", "rejected"), default="pending")
    created_at = Column(DateTime, default=datetime.utcnow)

class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True, index=True)
    employee_email = Column(String, index=True)
    date = Column(Date)
    time_in = Column(String)
    time_out = Column(String)
    total_hours = Column(Float)
    status = Column(String, default="present")