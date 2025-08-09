from pydantic import BaseModel, EmailStr
from typing import Optional

class EmployeeBase(BaseModel):
    name: str
    email: EmailStr
    phone: str
    gender: str
    department: str
    salary: float
    bank_name: str
    account_number: str

class EmployeeCreate(EmployeeBase):
    password: str

class EmployeeResponse(EmployeeBase):
    id: int
    is_admin: bool

    model_config = {"from_attributes": True}

EmployeeCreate.model_config['json_schema_extra'] = {
    "examples": [
        {
            "name": "Nicole Kagwanja",
            "email": "nicole@gmail.com",
            "phone": "0712345678",
            "gender": "Female",
            "department": "ICT",
            "salary": 85000.0,
            "bank_name": "Equity Bank",
            "account_number": "1234567890",
            "password": "12345"
        }
    ]
}

class AttendanceCreate(BaseModel):
    employee_email: str
    time_in: Optional[str] = None
    time_out: Optional[str] = None

class AttendanceResponse(BaseModel):
    id: int
    employee_email: str
    date: str
    time_in: Optional[str]
    time_out: Optional[str]
    total_hours: Optional[float]
    status: str
    model_config = {"from_attributes": True}

class OffWeekRequestCreate(BaseModel):
    email: EmailStr
    start: str
    end: str

    model_config = {"from_attributes": True}



class OffWeekRequestResponse(BaseModel):
    id: int
    employee_email: str
    start_date: str
    end_date: str
    status: str
    created_at: str
    model_config = {"from_attributes": True}

class LoginRequest(BaseModel):
    email: EmailStr
    password: str