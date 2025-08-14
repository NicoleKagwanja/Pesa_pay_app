from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from crud import get_employee_by_email
from database import get_db
from models import Attendance
from datetime import date, timedelta
from crud import get_employee_by_email

PUBLIC_HOLIDAYS = [
    date(2025, 1, 1),   # New Year
    date(2025, 4, 18),  # Good Friday
    date(2025, 4, 21),  # Easter Monday
    date(2025, 5, 1),   # Labour Day
    date(2025, 6, 1),   # Madaraka Day
]

def get_public_holidays_in_month(target_date: date):
    """Get all public holidays in the same month as target_date"""
    year, month = target_date.year, target_date.month
    return [h for h in PUBLIC_HOLIDAYS if h.year == year and h.month == month]

def is_work_day(d: date):
    """Check if a date is a work day (not weekend or holiday)"""
    return d.weekday() < 5 and d not in PUBLIC_HOLIDAYS

router = APIRouter(tags=["salary"])

@router.get("/salary/calculate/{email}")
def calculate_salary(email: str, db: Session = Depends(get_db)):
    """
    AI-Based Salary Calculation
    - Base salary per day
    - Subtract for unauthorized absences
    - Add overtime pay
    - Adjust for public holidays (double pay)
    """

    db_user = get_employee_by_email(db, email=email)
    if not db_user:
        raise HTTPException(status_code=404, detail="Employee not found")

    base_salary_per_day = db_user.salary / 25
    overtime_rate = 1000
    deduction_per_absence = base_salary_per_day * 1.5

    today = date.today()
    first_day_of_month = today.replace(day=1)

    attendance = (
        db.query(Attendance)
        .filter(
            Attendance.employee_email == email,
            Attendance.date >= first_day_of_month
        )
        .all()
    )

    work_days = 0
    overtime_hours = 0
    holiday_bonus = 0
    unauthorized_absences = 0

    for record in attendance:
        rec_date = record.date
        if record.status == "present":
            if rec_date in PUBLIC_HOLIDAYS:
                holiday_bonus += base_salary_per_day * 2
            else:
                work_days += 1
        elif record.status == "overtime":
            overtime_hours += 4  # Assume 4-hour overtime
        elif record.status == "absent":
            if is_work_day(rec_date):
                unauthorized_absences += 1

    base_pay = work_days * base_salary_per_day
    overtime_pay = overtime_hours * overtime_rate
    deductions = unauthorized_absences * deduction_per_absence
    final_salary = base_pay + overtime_pay + holiday_bonus - deductions

    return {
        "employee_id": db_user.id,
        "name": db_user.name,
        "department": db_user.department,
        "base_salary": round(db_user.salary, 2),
        "work_days": work_days,
        "overtime_hours": overtime_hours,
        "overtime_pay": round(overtime_pay, 2),
        "holiday_bonus": round(holiday_bonus, 2),
        "unauthorized_absences": unauthorized_absences,
        "deductions": round(deductions, 2),
        "final_salary": round(max(final_salary, 0), 2),
        "payment_date": (today.replace(day=5) + timedelta(days=30)).isoformat(),
        "status": "Calculated successfully"
    }