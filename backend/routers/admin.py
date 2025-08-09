from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import OffWeekRequest, Employee
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

@router.get("/admin/off-week/pending")
def get_pending_off_weeks(db: Session = Depends(get_db)):
    requests = (
        db.query(OffWeekRequest)
        .filter(OffWeekRequest.status == "pending")
        .all()
    )
    return [
        {
            "id": r.id,
            "employee_email": r.employee_email,
            "start_date": r.start_date.isoformat(),
            "end_date": r.end_date.isoformat(),
            "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None
        }
        for r in requests
    ]

@router.post("/admin/off-week/approve/{request_id}")
def approve_off_week(request_id: int, db: Session = Depends(get_db)):
    request = db.query(OffWeekRequest).filter(OffWeekRequest.id == request_id).first()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    if request.status != "pending":
        raise HTTPException(status_code=400, detail="Request already processed")

    request.status = "approved"
    db.commit()

    return {"message": "Off-week approved successfully", "request_id": request_id}

@router.post("/admin/off-week/reject/{request_id}")
def reject_off_week(request_id: int, db: Session = Depends(get_db)):
    request = db.query(OffWeekRequest).filter(OffWeekRequest.id == request_id).first()
    if not request:
        raise HTTPException(status_code=404, detail="Request not found")

    if request.status != "pending":
        raise HTTPException(status_code=400, detail="Request already processed")

    request.status = "rejected"
    db.commit()

    return {"message": "Off-week rejected", "request_id": request_id}