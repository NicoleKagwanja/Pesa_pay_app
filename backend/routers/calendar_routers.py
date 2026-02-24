# routes/calendar_routes.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from database import SessionLocal, Base, engine
from models import PublicHoliday, CalendarEvent

router = APIRouter(prefix="/admin", tags=["Calendar"])

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# GET /api/admin/calendar/events
@router.get("/calendar/events", operation_id="getCalendarEvents")
def get_calendar_events(db: Session = Depends(get_db)):
    """
    Get all calendar events including:
    - Public holidays (from PublicHoliday table)
    - Custom events (funerals, trips, etc. from CalendarEvent table)
    """
    events = []

    # 1. Add public holidays
    holidays = db.query(PublicHoliday).all()
    for h in holidays:
        events.append({
            "id": h.id,
            "title": h.name,
            "date": str(h.date),
            "type": "holiday",
            "source": "system",
            "editable": False
        })

    # 2. Add custom calendar events (funerals, trips, etc.)
    custom_events = db.query(CalendarEvent).order_by(CalendarEvent.date).all()
    for e in custom_events:
        events.append({
            "id": e.id,
            "title": e.title,
            "date": str(e.date),
            "type": e.type,
            "description": e.description,
            "source": "custom",
            "editable": True
        })

    # Sort all events by date
    events.sort(key=lambda x: x["date"])
    return events

# POST /api/admin/calendar/events
@router.post("/calendar/events", operation_id="createCalendarEvent", status_code=201)
def create_calendar_event(
    title: str,
    date: str,
    type: str,
    description: str = None,
    db: Session = Depends(get_db)
):
    """
    Add a new event to the calendar (e.g., funeral, trip, official event)
    Admin-only endpoint.
    """
    # Validate date format
    try:
        event_date = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Invalid date format. Use YYYY-MM-DD"
        )

    # Validate event type
    valid_types = ["holiday", "event", "funeral", "trip", "official"]
    if type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Type must be one of {valid_types}"
        )

    # Check for duplicate event (same title, date, type)
    existing = db.query(CalendarEvent).filter(
        CalendarEvent.title == title,
        CalendarEvent.date == event_date,
        CalendarEvent.type == type
    ).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail="An event with this title, date, and type already exists."
        )

    # Create new event
    event = CalendarEvent(
        title=title,
        date=event_date,
        type=type,
        description=description
    )

    try:
        db.add(event)
        db.commit()
        db.refresh(event)

        return {
            "id": event.id,
            "title": event.title,
            "date": str(event.date),
            "type": event.type,
            "description": event.description,
            "message": "✅ Event added to calendar"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to save event: {str(e)}")