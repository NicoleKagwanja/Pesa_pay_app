from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import OffWeekRequest
from schemas import OffWeekRequestCreate
from datetime import datetime

router = APIRouter(prefix="/api/v1", tags=["off-week"])

@router.post("/off-week/request")
def request_off_week(
    request: OffWeekRequestCreate,
    db: Session = Depends(get_db)
):
    """
    Submit an off-week request for an employee.
    Expects JSON body:
    {
        "email": "ann@gmail.com",
        "start": "2025-04-10",
        "end": "2025-04-17"
    }
    """
    try:
        start_date = datetime.strptime(request.start, "%Y-%m-%d").date()
        end_date = datetime.strptime(request.end, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid date format. Use YYYY-MM-DD."
        )

    if end_date < start_date:
        raise HTTPException(
            status_code=400,
            detail="End date cannot be before start date."
        )

    new_request = OffWeekRequest(
        employee_email=request.email,
        start_date=start_date,
        end_date=end_date,
        status="pending"
    )

    # Save to database
    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    return {
        "message": "Off-week request submitted successfully",
        "id": new_request.id
    }