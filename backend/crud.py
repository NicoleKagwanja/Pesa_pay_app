from sqlalchemy.orm import Session
from models import Employee
from schemas import EmployeeCreate
from argon2 import PasswordHasher

ph = PasswordHasher()

def get_employee(db: Session, employee_id: int):
    """
    Retrieve an employee by their unique ID.
    """
    return db.query(Employee).filter(Employee.id == employee_id).first()


def get_employee_by_email(db: Session, email: str):
    """
    Retrieve an employee by their email (used for login and registration).
    """
    return db.query(Employee).filter(Employee.email == email).first()


def get_employee_by_name(db: Session, name: str):
    """
    Retrieve an employee by their full name (useful for search or display).
    """
    return db.query(Employee).filter(Employee.name == name).first()


def get_all_employees(db: Session):
    """
    Retrieve all employees (useful for admin panels or reports).
    """
    return db.query(Employee).all()


def create_employee(db: Session, employee: EmployeeCreate):
    """
    Create a new employee in the database.
    - The password is securely hashed using Argon2 before storage.
    - All other employee details are saved as provided.
    """

    hashed_password = ph.hash(employee.password)

    db_employee = Employee(
        name=employee.name,
        email=employee.email,
        phone=employee.phone,
        gender=employee.gender,
        department=employee.department,
        salary=employee.salary,
        bank_name=employee.bank_name,
        account_number=employee.account_number,
        password=hashed_password  # ✅ Store the secure hash
    )

    # Save to database
    db.add(db_employee)
    db.commit()
    db.refresh(db_employee)
    return db_employee


def authenticate_employee(db: Session, email: str, password: str):
    """
    Authenticate an employee during login.
    - Finds the employee by email
    - Verifies the provided password against the stored hash
    - Returns the employee object if successful, None otherwise
    """
    employee = get_employee_by_email(db, email=email)
    if not employee:
        return None

    try:
        ph.verify(employee.hashed_password, password)
        return employee
    except Exception:
        return None