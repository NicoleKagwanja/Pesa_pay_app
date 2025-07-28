from database import engine, SessionLocal
from models import Base
from crud import create_employee, get_all_employees, get_employee_by_name
from schemas import EmployeeCreate

print("🔧 Creating database tables...")
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
    create_employee(db=db, employee=nicole_data)
    print("Nicole Kagwanja added to database!")
else:
    print("Nicole Kagwanja already exists.")


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
    print("John Mwangi added!")
else:
    print("John Mwangi already exists.")

print("\nAll Employees in Database:")
employees = get_all_employees(db)
for emp in employees:
    print(f"ID: {emp.id} | Name: {emp.name} | Dept: {emp.department}")

db.close()