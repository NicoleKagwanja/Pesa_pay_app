from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, date
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from database import get_db
from models import Attendance, Employee, SharedEvent
from sqlalchemy import and_

router = APIRouter(prefix="/admin", tags=["admin"])


class SharedEventCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=500)
    event_date: date
    event_type: str = "general"
    target_department: Optional[str] = None

class SharedEventResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    event_date: str
    event_type: str
    created_by: str
    created_at: str
    is_active: bool
    
    class Config:
        from_attributes = True

class EmployeeAttendanceSummary(BaseModel):
    email: str
    name: str
    department: str
    today_status: Optional[str]
    time_in: Optional[str]
    time_out: Optional[str]
    total_hours_today: Optional[float]
    month_hours: float
    month_days: int


@router.get("/employees", response_model=List[dict], operation_id="admin_list_employees")
def list_employees(db: Session = Depends(get_db)):

    employees = db.query(Employee).all()
    return [
        {
            "email": e.email,
            "name": e.name,
            "department": e.department,
            "role": e.role,
            "is_active": e.is_active if hasattr(e, 'is_active') else True,
        }
        for e in employees
    ]

@router.get("/employees/{email}/attendance", operation_id="admin_get_employee_attendance")
def get_employee_attendance(email: str, date: Optional[date] = None, db: Session = Depends(get_db)):

    if date:
        record = db.query(Attendance).filter(
            Attendance.employee_email == email,
            Attendance.date == date
        ).first()
        
        if not record:
            return {"date": date.isoformat(), "has_record": False}
        
        return {
            "date": record.date.isoformat(),
            "has_record": True,
            "time_in": record.time_in,
            "time_out": record.time_out,
            "total_hours": record.total_hours,
            "status": record.status,
        }
    else:
        from datetime import timedelta
        today = date.today()
        month_start = date(today.year, today.month, 1)
        
        records = db.query(Attendance).filter(
            Attendance.employee_email == email,
            Attendance.date >= month_start
        ).all()
        
        total_hours = sum(r.total_hours for r in records if r.total_hours)
        days_present = len([r for r in records if r.time_in])
        
        return {
            "employee_email": email,
            "month": f"{today.year}-{today.month:02d}",
            "total_hours": round(total_hours, 2),
            "days_present": days_present,
            "records_count": len(records),
        }

@router.get("/attendance/overview", operation_id="admin_attendance_overview")
def get_attendance_overview(db: Session = Depends(get_db)):

    today = date.today()
    employees = db.query(Employee).all()
    overview = []
    
    for emp in employees:
        today_record = db.query(Attendance).filter(
            Attendance.employee_email == emp.email,
            Attendance.date == today
        ).first()

        month_start = date(today.year, today.month, 1)
        month_records = db.query(Attendance).filter(
            Attendance.employee_email == emp.email,
            Attendance.date >= month_start
        ).all()
        
        month_hours = sum(r.total_hours for r in month_records if r.total_hours)
        month_days = len([r for r in month_records if r.time_in])

        if not today_record:
            status = "absent"
        elif today_record.time_in and not today_record.time_out:
            status = "clocked_in"
        elif today_record.time_in and today_record.time_out:
            status = "present"
        else:
            status = "unknown"
        
        overview.append({
            "email": emp.email,
            "name": emp.name or emp.email.split('@')[0],
            "department": emp.department or "Unknown",
            "today_status": status,
            "time_in": today_record.time_in if today_record else None,
            "time_out": today_record.time_out if today_record else None,
            "month_hours": round(month_hours, 2),
            "month_days": month_days,
        })
    
    return {
        "date": today.isoformat(),
        "total_employees": len(employees),
        "present_count": len([e for e in overview if e['today_status'] in ['present', 'clocked_in']]),
        "employees": overview,
    }


@router.post("/events", response_model=SharedEventResponse, operation_id="admin_create_shared_event")
def create_shared_event(
    event: SharedEventCreate, 
    admin_email: EmailStr,
    db: Session = Depends(get_db)
):

    
    new_event = SharedEvent(
        title=event.title,
        description=event.description,
        event_date=event.event_date,
        event_type=event.event_type,
        target_department=event.target_department,
        created_by=admin_email,
    )
    
    db.add(new_event)
    db.commit()
    db.refresh(new_event)
    
    return new_event

@router.get("/events", response_model=List[SharedEventResponse], operation_id="get_shared_events")
def get_shared_events(
    month: Optional[str] = None,
    department: Optional[str] = None,
    db: Session = Depends(get_db)
):

    query = db.query(SharedEvent).filter(SharedEvent.is_active == True)

    if month:
        try:
            year, mo = map(int, month.split('-'))
            month_start = date(year, mo, 1)
            month_end = date(year, mo + 1, 1) if mo < 12 else date(year + 1, 1, 1)
            query = query.filter(
                and_(SharedEvent.event_date >= month_start, SharedEvent.event_date < month_end)
            )
        except:
            pass
 
    if department:
        query = query.filter(
            (SharedEvent.target_department == None) | 
            (SharedEvent.target_department == department)
        )
    else:

        query = query.filter(SharedEvent.target_department == None)
    
    events = query.order_by(SharedEvent.event_date.desc()).all()
    return events

@router.delete("/events/{event_id}", operation_id="admin_delete_shared_event")
def delete_shared_event(
    event_id: int, 
    admin_email: EmailStr,
    db: Session = Depends(get_db)
):

    event = db.query(SharedEvent).filter(SharedEvent.id == event_id).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    event.is_active = False
    db.commit()
    
    return {"message": "Event deactivated", "event_id": event_id}