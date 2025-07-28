from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal, Base, engine
from models import Employee, OffWeekRequest, Attendance
from schemas import EmployeeCreate, Employee
from crud import create_employee, get_employee_by_email, get_all_employees
from datetime import date, datetime
from passlib.context import CryptContext

ph = CryptContext(schemes=["argon2"], deprecated="auto")

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

Base.metadata.create_all(bind=engine)

@router.post("/signup", response_model=Employee)
def register_employee(employee: EmployeeCreate, db: Session = Depends(get_db)):
    """
    Register a new county employee.
    Request Body:
    {
        "name": "Nicole Kagwanja",
        "email": "nicole@gmail.com",
        "phone": "0712345678",
        "gender": "Female",
        "department": "ICT",
        "salary": 85000,
        "bank_name": "Equity Bank",
        "account_number": "1234567890",
        "password": "12345"
    }
    """
    db_user = get_employee_by_email(db, email=employee.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    return create_employee(db=db, employee=employee)


@router.get("/employees", response_model=list[Employee])
def get_all_employees_endpoint(db: Session = Depends(get_db)):
    """Get a list of all employees."""
    return get_all_employees(db)


@router.get("/employee/{email}", response_model=Employee)
def get_employee_by_email_endpoint(email: str, db: Session = Depends(get_db)):
    """Get a single employee by email."""
    db_user = get_employee_by_email(db, email=email)
    if not db_user:
        raise HTTPException(status_code=404, detail="Employee not found")
    return db_user


@router.get("/salary/calculate/{email}")
def calculate_salary(email: str, db: Session = Depends(get_db)):
    """AI-based salary calculation."""
    db_user = get_employee_by_email(db, email=email)
    if not db_user:
        raise HTTPException(status_code=404, detail="Employee not found")

    base_salary = db_user.salary
    overtime_hours = 8
    overtime_rate = 1000
    deductions = 0

    overtime_pay = overtime_hours * overtime_rate
    final_salary = base_salary + overtime_pay - deductions

    return {
        "employee_id": db_user.id,
        "name": db_user.name,
        "department": db_user.department,
        "base_salary": base_salary,
        "overtime_hours": overtime_hours,
        "overtime_pay": overtime_pay,
        "deductions": deductions,
        "final_salary": final_salary,
        "payment_date": "2025-04-05",
        "status": "Calculated successfully"
    }


@router.get("/activity/calendar/{email}")
def get_activity_calendar(email: str, db: Session = Depends(get_db)):
    """Get personalized calendar."""
    db_user = get_employee_by_email(db, email=email)
    if not db_user:
        raise HTTPException(status_code=404, detail="Employee not found")

    return {
        "employee": {
            "name": db_user.name,
            "department": db_user.department
        },
        "calendar": {
            "off_weeks": ["2025-04-05", "2025-04-19"],
            "holidays": ["2025-04-18", "2025-05-01"],
            "events": [
                {"title": "Official Trip", "date": "2025-04-20", "type": "trip"},
                {"title": "Funeral", "date": "2025-04-12", "type": "funeral"}
            ]
        },
        "message": "Calendar loaded successfully"
    }


@router.post("/login")
def login(employee_login: dict, db: Session = Depends(get_db)):
    """
    Login with email and password.
    Request Body: {"email": "...", "password": "..."}
    """
    email = employee_login.get("email")
    password = employee_login.get("password")

    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password required")

    db_user = get_employee_by_email(db, email=email)
    if not db_user:
        raise HTTPException(status_code=404, detail="Employee not found")

    if not ph.verify(password, db_user.password):  # type: ignore # In real app, use hash check
        raise HTTPException(status_code=401, detail="Incorrect password")

    return {
        "message": "Login successful",
        "employee": {
            "id": db_user.id,
            "name": db_user.name,
            "email": db_user.email,
            "phone": db_user.phone,
            "gender": db_user.gender,
            "department": db_user.department,
            "salary": db_user.salary,
            "bank_name": db_user.bank_name,
            "account_number": db_user.account_number
        }
    }


@router.get("/attendance/{email}")
def get_attendance(email: str, db: Session = Depends(get_db)):
    """Get employee attendance summary."""
    records = db.query(Attendance).filter(Attendance.employee_email == email).all()
    present_days = len([r for r in records if r.status == "present"])
    total_days = len(records)

    return {
        "employee_email": email,
        "attendance_records": [
            {"date": str(r.date), "status": r.status} for r in records
        ],
        "summary": f"{present_days}/{total_days} days present"
    }


@router.post("/off-week/request")
def request_off_week(
    employee_email: str,
    start_date: str,
    end_date: str,
    db: Session = Depends(get_db)
):
    try:
        start = datetime.date.fromisoformat(start_date)
        end = datetime.date.fromisoformat(end_date)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")

    new_request = OffWeekRequest(
        employee_email=employee_email,
        start_date=start,
        end_date=end,
        status="pending"
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    return {
        "message": "Off-week request submitted successfully",
        "request": {
            "id": new_request.id,
            "employee_email": new_request.employee_email,
            "start_date": new_request.start_date.isoformat(),
            "end_date": new_request.end_date.isoformat(),
            "status": new_request.status
        }
    }