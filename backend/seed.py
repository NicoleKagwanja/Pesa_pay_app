from database import engine, SessionLocal
from models import Base, Employee
from crud import create_employee, get_all_employees, get_employee_by_name
from schemas import EmployeeCreate

print("Creating database tables...")
Base.metadata.create_all(bind=engine)
print("Tables created!")

db = SessionLocal()
nicole = get_employee_by_name(db, "Nicole Kagwanja")
if not nicole:
    nicole_data = EmployeeCreate(
        name="Nicole Kagwanja",
        email="nicole@gmail.com",
        phone="0712345678",
        gender="Female",
        department="ICT",
        salary=85000.0,
        bank_name="Equity Bank",
        account_number="1234567890",
        password="12345"
    )
    nicole = create_employee(db=db, employee=nicole_data)
    print("Nicole Kagwanja added to database!")
else:
    print("Nicole Kagwanja already exists in the database.")

try:
    nicole = db.query(Employee).filter(Employee.email == "nicole@gmail.com").first()
    if nicole:
        if not nicole.is_admin:
            nicole.is_admin = True
            db.commit()
            print(f"✅ Admin rights granted to {nicole.name}")
        else:
            print(f"ℹ️ {nicole.name} already has admin rights.")
    else:
        print("❌ User not found: nicole@gmail.com")
except Exception as e:
    print(f"Error setting admin rights: {e}")
    db.rollback()

john = get_employee_by_name(db, "John Mwangi")
if not john:
    john_data = EmployeeCreate(
        name="John Mwangi",
        email="john@gmail.com",
        phone="0722334455",
        gender="Male",
        department="Finance",
        salary=78000.0,
        bank_name="KCB",
        account_number="9876543210",
        password="123456"
    )
    create_employee(db=db, employee=john_data)
    print("John Mwangi added to database!")
else:
    print("John Mwangi already exists.")

print("\n📋 All Employees in Database:")
employees = get_all_employees(db)
for emp in employees:
    admin_status = "👑 Admin" if getattr(emp, 'is_admin', False) else "👤 Employee"
    print(f"ID: {emp.id} | Name: {emp.name} | Dept: {emp.department} | Role: {admin_status}")

db.close()