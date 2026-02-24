from datetime import date, datetime
from pydantic import BaseModel, EmailStr
from typing import Optional, List


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
    salary: float = 80000


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
    date: date
    time_in: Optional[str] = None
    time_out: Optional[str] = None
    total_hours: Optional[float] = None
    status: str

    model_config = {"from_attributes": True}


class OffWeekRequestCreate(BaseModel):
    employee_email: EmailStr
    start_date: date
    end_date: date
    reason: str

    model_config = {
        "json_schema_extra": {
            "example": {
                "employee_email": "ann@gmail.com",
                "start_date": "2025-08-15",
                "end_date": "2025-08-20",
                "reason": "Family vacation"
            }
        },
        "from_attributes": True
    }


class OffWeekRequestResponse(BaseModel):
    id: int
    employee_email: str
    start_date: date
    end_date: date
    reason: str
    status: str
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class OffWeekRequestListResponse(BaseModel):
    count: int
    requests: List[OffWeekRequestResponse]


class LoginRequest(BaseModel):
    email: EmailStr
    password: str