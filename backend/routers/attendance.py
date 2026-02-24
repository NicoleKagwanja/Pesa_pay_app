from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, date, timedelta
import pytz # type: ignore
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List
from database import SessionLocal
from models import Attendance
from sqlalchemy.exc import IntegrityError

router = APIRouter(tags=["attendance"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

ea_tz = pytz.timezone("Africa/Nairobi")


class AttendanceCreate(BaseModel):
    employee_email: EmailStr
    time_in: Optional[str] = None
    time_out: Optional[str] = None

    @field_validator("time_in", "time_out", mode="before")
    @classmethod
    def validate_time_format(cls, v):
        if v is None:
            return v
        try:
            datetime.strptime(v, "%H:%M")
            return v
        except ValueError:
            raise ValueError("Time must be in HH:MM format (e.g., 08:30)")

    def validate_action(self):
        if not self.time_in and not self.time_out:
            raise ValueError("Either 'time_in' or 'time_out' must be provided.")
        return self


class AttendanceRequest(BaseModel):
    employee_email: EmailStr
    date: date
    time_in: Optional[str] = None
    time_out: Optional[str] = None
    total_hours: Optional[float] = None
    status: str = "present"

    @field_validator("time_in", "time_out", mode="before")
    @classmethod
    def validate_time_format(cls, v):
        if v is None:
            return v
        try:
            datetime.strptime(v, "%H:%M")
            return v
        except ValueError:
            raise ValueError("Time must be in HH:MM format (e.g., 08:30)")

class AttendanceRecordResponse(BaseModel):
    id: int
    date: str
    time_in: Optional[str]
    time_out: Optional[str]
    total_hours: Optional[float]

    class Config:
        from_attributes = True

@router.post("/attendance/log", operation_id="log_attendance_clock_in_out")
def log_attendance(data: AttendanceCreate, db: Session = Depends(get_db)):
    try:
        data.validate_action()
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    now_ea = datetime.now(ea_tz)
    today: date = now_ea.date()
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
                time_in=data.time_in,
                status="present",
            )
            db.add(record)
        else:
            record.time_in = data.time_in

        try:
            db.commit()
            db.refresh(record)
            return {
                "message": "Clocked in successfully",
                "time_in": record.time_in,
                "date": record.date.isoformat(),
            }
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=500, detail="Failed to log attendance (database error).")
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail="Internal server error.")

    elif data.time_out is not None:
        if not record or not record.time_in:
            raise HTTPException(status_code=400, detail="Must clock in before clocking out.")
        if record.time_out:
            raise HTTPException(status_code=400, detail="Already clocked out today.")

        time_in_str = record.time_in
        time_out_str = data.time_out or current_time

        try:
            time_in_dt = datetime.strptime(time_in_str, "%H:%M")
            time_out_dt = datetime.strptime(time_out_str, "%H:%M")

            if time_out_dt < time_in_dt:
                if time_out_dt.hour < 12:
                    time_out_dt += timedelta(days=1)
                else:
                    raise HTTPException(
                        status_code=400,
                        detail="Time-out cannot be earlier than time-in unless past midnight."
                    )

            total_seconds = (time_out_dt - time_in_dt).seconds
            hours_worked = round(total_seconds / 3600, 2)

        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid time format or logic: {str(e)}")

        record.time_out = time_out_str
        record.total_hours = hours_worked

        try:
            db.commit()
            db.refresh(record)
            return {
                "message": "Clocked out successfully",
                "time_out": record.time_out,
                "total_hours": record.total_hours,
                "date": record.date.isoformat(),
            }
        except Exception as e:
            db.rollback()
            raise HTTPException(status_code=500, detail="Failed to update attendance.")


@router.post("/attendance/manual", operation_id="admin_create_manual_attendance")
def create_attendance_manual(request: AttendanceRequest, db: Session = Depends(get_db)):
    record = (
        db.query(Attendance)
        .filter(
            Attendance.employee_email == request.employee_email,
            Attendance.date == request.date
        )
        .first()
    )

    if not record:
        record = Attendance(
            employee_email=request.employee_email,
            date=request.date,
            time_in=request.time_in,
            time_out=request.time_out,
            total_hours=request.total_hours,
            status=request.status,
        )
        db.add(record)
    else:
        if request.time_in is not None:
            record.time_in = request.time_in
        if request.time_out is not None:
            record.time_out = request.time_out
        if request.total_hours is not None:
            record.total_hours = request.total_hours
        record.status = request.status

    try:
        db.commit()
        db.refresh(record)
        return {
            "message": "Attendance logged successfully",
            "attendance": {
                "employee_email": record.employee_email,
                "date": record.date.isoformat(),
                "time_in": record.time_in,
                "time_out": record.time_out,
                "total_hours": record.total_hours,
                "status": record.status,
            }
        }
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Attendance record already exists for this date.")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Internal server error.")


@router.get("/attendance/records/{email}", response_model=List[AttendanceRecordResponse], operation_id="get_attendance_records")
def get_attendance_records(email: str, db: Session = Depends(get_db)):
    records = db.query(Attendance).filter(
        Attendance.employee_email == email
    ).order_by(Attendance.date.desc()).all()
    
    return records


@router.get("/attendance/summary/{email}", operation_id="get_employee_attendance_summary")
def get_attendance_summary(email: str, db: Session = Depends(get_db)):
    records = db.query(Attendance).filter(Attendance.employee_email == email).all()
    total_hours = sum(r.total_hours for r in records if r.total_hours is not None)
    days_worked = len([r for r in records if r.time_in])

    return {
        "employee_email": email,
        "total_hours": round(total_hours, 2),
        "days_present": days_worked, 
        "summary": f"Worked {days_worked} days, {total_hours:.1f} hours this month"
    }


@router.get("/admin/attendance/report", operation_id="get_admin_attendance_report")
def get_attendance_report(db: Session = Depends(get_db)):

    employee_emails = db.query(Attendance.employee_email).distinct().all()
    report = []

    for (email,) in employee_emails:
        records = db.query(Attendance).filter(Attendance.employee_email == email).all()
        total_hours = sum(r.total_hours for r in records if r.total_hours is not None)
        name = email.split("@")[0].replace(".", " ").title()

        report.append({
            "name": name,
            "email": email,
            "department": "Unknown",
            "total_hours": round(total_hours, 2),
            "attendance_days": len([r for r in records if r.time_in]),
        })

    return report