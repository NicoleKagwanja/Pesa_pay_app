from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import OffWeekRequest
from schemas import OffWeekRequestCreate, OffWeekRequestListResponse, OffWeekRequestResponse

router = APIRouter(tags=["off-week"])


@router.post(
    "/off-week/request",
    response_model=OffWeekRequestResponse,
    summary="Submit an off-week request",
    description="Employees can request time off. Status defaults to 'pending'.",
    
)
def request_off_week(
    request: OffWeekRequestCreate,
    db: Session = Depends(get_db)
):
    """
    Submit an off-week request for an employee.
    """
    if request.end_date < request.start_date:
        raise HTTPException(
            status_code=400,
            detail="End date cannot be before start date."
        )

    existing = db.query(OffWeekRequest).filter(
        OffWeekRequest.employee_email == request.employee_email,
        OffWeekRequest.status == "approved",
        OffWeekRequest.start_date <= request.end_date,
        OffWeekRequest.end_date >= request.start_date
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail="You have an overlapping approved off-week request."
        )

    new_request = OffWeekRequest(
        employee_email=request.employee_email,
        start_date=request.start_date,
        end_date=request.end_date,
        reason=request.reason,
        status="pending"
    )

    try:
        db.add(new_request)
        db.commit()
        db.refresh(new_request)
        return new_request
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to submit request. Please try again.")

@router.get(
    "/admin/off-week/pending",
    operation_id="admin_get_pending_off_week_requests",
    summary="Get all pending off-week requests",
    response_description="List of pending off-week requests",
    response_model=OffWeekRequestListResponse,
)
def get_pending_requests(db: Session = Depends(get_db)):
    requests = db.query(OffWeekRequest).filter(OffWeekRequest.status == "pending").all()

    return {
        "count": len(requests),
        "requests": requests
    }


@router.post(
    "/admin/off-week/approve/{request_id}",
    operation_id="admin_approve_off_week",
    summary="Approve an off-week request",
    description="Admin-only: Approve a pending off-week request by ID."
)
def approve_request(request_id: int, db: Session = Depends(get_db)):
    db_request = db.query(OffWeekRequest).filter(OffWeekRequest.id == request_id).first()
    if not db_request:
        raise HTTPException(status_code=404, detail="Request not found")

    if db_request.status != "pending":
        raise HTTPException(status_code=400, detail=f"Request is already {db_request.status}")

    db_request.status = "approved"
    try:
        db.commit()
        return {"message": "Off-week request approved successfully", "id": request_id}
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to approve request")

@router.post(
    "/admin/off-week/reject/{request_id}",
    operation_id="admin_reject_off_week",
    summary="Reject an off-week request",
    description="Admin-only: Reject a pending off-week request by ID."
)
def reject_request(request_id: int, db: Session = Depends(get_db)):
    db_request = db.query(OffWeekRequest).filter(OffWeekRequest.id == request_id).first()
    if not db_request:
        raise HTTPException(status_code=404, detail="Request not found")

    if db_request.status != "pending":
        raise HTTPException(status_code=400, detail=f"Request is already {db_request.status}")

    db_request.status = "rejected"
    try:
        db.commit()
        return {"message": "Off-week request rejected successfully", "id": request_id}
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to reject request")