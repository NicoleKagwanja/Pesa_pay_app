from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Attendance, Employee
from datetime import datetime

router = APIRouter(tags=["admin"])

@router.post("/payments/disburse")
def disburse_salaries(db: Session = Depends(get_db)):
    """
    Trigger salary disbursement for all active employees.
    Simulates bank transfer via IPF (Inter-Bank Payment Framework).
    """
    employees = db.query(Employee).all()
    successful = 0

    for emp in employees:
        if emp.salary <= 0 or not emp.bank_name or not emp.account_number:
            continue

        successful += 1

    return {
        "status": "success",
        "message": f"Salaries disbursed to {successful} employees via IPF.",
        "count": successful,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }

@router.get("/admin/employees")
def get_all_employees(db: Session = Depends(get_db)):
    employees = db.query(Employee).all()
    return [
        {
            "id": e.id,
            "name": e.name,
            "email": e.email,
            "department": e.department,
            "phone": e.phone,
            "salary": e.salary,
            "bank_name": e.bank_name,
            "account_number": e.account_number,
            "gender": e.gender,
            "is_admin": e.is_admin
        }
        for e in employees
    ]

@router.get("/admin/attendance/report")
def get_attendance_report(db: Session = Depends(get_db)):
    """
    Get full attendance report with total hours per employee
    """
    employees = db.query(Employee).all()
    report = []

    for emp in employees:
        records = db.query(Attendance).filter(Attendance.employee_email == emp.email).all()
        total_hours = sum(r.total_hours or 0 for r in records)

        report.append({
            "id": emp.id,
            "name": emp.name,
            "email": emp.email,
            "department": emp.department,
            "total_hours": round(total_hours, 2),
            "attendance_count": len(records)
        })

    return report