from pydantic import BaseModel, EmailStr

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

class Employee(EmployeeBase):
    id: int

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