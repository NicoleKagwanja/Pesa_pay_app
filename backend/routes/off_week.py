from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal, Base, engine
from models import OffWeekRequest
from datetime import date
import json

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

Base.metadata.create_all(bind=engine)

@router.post("/off-week/request", operation_id="create_off_week_request")
def request_off_week(
    employee_email: str,
    start_date: str,  # Format: "2025-04-05"
    end_date: str,
    db: Session = Depends(get_db)
):

    try:
        start = date.fromisoformat(start_date)
        end = date.fromisoformat(end_date)
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
    return {"message": "Off-week request submitted", "request": new_request}