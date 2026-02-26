from datetime import datetime
from sqlalchemy import Boolean, Column, Date, DateTime, Enum, Float, Integer, String, Text
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

class Attendance(Base):
    __tablename__ = "attendance"

    id = Column(Integer, primary_key=True, index=True)
    employee_email = Column(String, index=True)
    date = Column(Date)
    time_in = Column(String)
    time_out = Column(String)
    total_hours = Column(Float)
    status = Column(String, default="present")

class PublicHoliday(Base):
    __tablename__ = "public_holidays"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    date = Column(Date, nullable=False, index=True)

class CalendarEvent(Base):
    __tablename__ = "calendar_events"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    date = Column(Date, nullable=False)
    type = Column(String, nullable=False)
    description = Column(Text, nullable=True)

class SharedEvent(Base):
    __tablename__ = "shared_events"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    event_date = Column(Date, nullable=False, index=True)
    event_type = Column(String, default="general")
    created_by = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    
    
    target_department = Column(String, nullable=True)