from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import pytz
from pydantic import BaseModel
from typing import Optional
from database import SessionLocal
from models import Attendance

router = APIRouter(tags=["attendance"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

ea_tz = pytz.timezone("Africa/Nairobi")

class AttendanceCreate(BaseModel):
    employee_email: str
    time_in: Optional[str] = None
    time_out: Optional[str] = None

    def validate_action(self):
        if not self.time_in and not self.time_out:
            raise ValueError("Either 'time_in' or 'time_out' must be provided.")
        return self


@router.post("/attendance/log")
def log_attendance(data: AttendanceCreate, db: Session = Depends(get_db)):
    """
    Log time-in or time-out for an employee.
    - If time_in is provided: Clock in (must not already be clocked in today).
    - If time_out is provided: Clock out (must have clocked in first).
    """
    try:
        data.validate_action()
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    now_ea = datetime.now(ea_tz)
    today = now_ea.strftime("%Y-%m-%d")
    current_time = now_ea.strftime("%H:%M")
    record = (
        db.query(Attendance)
        .filter(Attendance.employee_email == data.employee_email, Attendance.date == today)
        .first()
    )

    if data.time_in is not None:
        if record and record.time_in:
            raise HTTPException(status_code=400, detail="Already clocked in today.")
        if not record:
            record = Attendance(
                employee_email=data.employee_email,
                date=today,
                time_in=data.time_in,  # Use provided time_in
            )
            db.add(record)
        else:
            record.time_in = data.time_in
        db.commit()
        db.refresh(record)
        return {"message": "Clocked in successfully", "time_in": record.time_in, "date": today}
    elif data.time_out is not None:
        if not record or not record.time_in:
            raise HTTPException(status_code=400, detail="Must clock in before clocking out.")
        if record.time_out:
            raise HTTPException(status_code=400, detail="Already clocked out today.")
        try:
            time_in_dt = datetime.strptime(record.time_in, "%H:%M")
            time_out_str = data.time_out or current_time
            time_out_dt = datetime.strptime(time_out_str, "%H:%M")
            if time_out_dt < time_in_dt:
                if time_out_dt.hour < 6:
                    time_out_dt += timedelta(days=1)
                else:
                    raise HTTPException(status_code=400, detail="Invalid time-out before time-in.")
            total_seconds = (time_out_dt - time_in_dt).seconds
            hours_worked = round(total_seconds / 3600, 2)

        except Exception:
            raise HTTPException(status_code=400, detail="Invalid time format.")
        record.time_out = time_out_str
        record.total_hours = hours_worked
        db.commit()
        db.refresh(record)

        return {
            "message": "Clocked out successfully",
            "time_out": record.time_out,
            "total_hours": record.total_hours,
            "date": today,
        }

@router.get("/attendance/summary/{email}")
def get_attendance_summary(email: str, db: Session = Depends(get_db)):

    total_hours = sum([
        a.total_hours or 0
        for a in db.query(Attendance).filter(Attendance.employee_email == email).all()
    ])
    days_worked = db.query(Attendance).filter(Attendance.employee_email == email).count()

    return {
        "employee_email": email,
        "total_hours": round(total_hours, 2),
        "days_worked": days_worked,
        "summary": f"Worked {days_worked} days, {total_hours:.1f} hours this month"
    }

@router.get("/admin/attendance/report")
def get_attendance_report(db: Session = Depends(get_db)):
    """
    Admin endpoint: Get attendance summary for all employees.
    """
    employee_emails = db.query(Attendance.employee_email).distinct().all()
    report = []

    for (email,) in employee_emails:
        records = db.query(Attendance).filter(Attendance.employee_email == email).all()
        total_hours = sum(r.total_hours for r in records if r.total_hours is not None)
        report.append({
            "name": email.split("@")[0].replace(".", " ").title(),
            "email": email,
            "department": "Unknown",
            "total_hours": round(total_hours, 2),
            "attendance_days": len([r for r in records if r.time_in]),
        })

    return report