from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Employee, Attendance
from datetime import date, timedelta
from datetime import datetime as dt

router = APIRouter(tags=["salary"])

PUBLIC_HOLIDAYS = [
    date(2025, 1, 1),   # New Year
    date(2025, 4, 18),  # Good Friday
    date(2025, 4, 21),  # Easter Monday
    date(2025, 5, 1),   # Labour Day
    date(2025, 6, 1),   # Madaraka Day
    date(2025, 10, 20), # Mashujaa Day
    date(2025, 12, 12), # Jamhuri Day
    date(2025, 12, 25), # Christmas
    date(2025, 12, 26), # Boxing Day
]

def is_work_day(d: date) -> bool:
    """Check if a date is a work day (not weekend or public holiday)"""
    return d.weekday() < 5 and d not in PUBLIC_HOLIDAYS

def get_work_days_in_month(target_date: date) -> int:
    """Calculate total work days in the month (excluding weekends and holidays)"""
    year, month = target_date.year, target_date.month
    days_in_month = (target_date.replace(month=month % 12 + 1, day=1) - timedelta(days=1)).day
    work_days = 0
    for day in range(1, days_in_month + 1):
        current = date(year, month, day)
        if is_work_day(current):
            work_days += 1
    return work_days

@router.get("/salary/calculate/{email}")
def calculate_salary(email: str, db: Session = Depends(get_db)):
    """
    AI-Based Salary Calculation
    - Base salary per day
    - Subtract for unauthorized absences
    - Add overtime pay (1.5x)
    - Double pay for public holidays
    - Uses actual time_in/time_out for fairness
    """

    employee = db.query(Employee).filter(Employee.email == email).first()
    if not employee:
        raise HTTPException(status_code=404, detail="Employee not found")

    base_monthly_salary = employee.salary
    work_days_in_month = get_work_days_in_month(date.today())
    base_daily_salary = base_monthly_salary / work_days_in_month
    hourly_rate = base_daily_salary / 8
    overtime_rate_multiplier = 1.5
    deduction_factor = 1.5

    today = date.today()
    first_day_of_month = today.replace(day=1)

    attendance_records = (
        db.query(Attendance)
        .filter(
            Attendance.employee_email == email,
            Attendance.date >= first_day_of_month
        )
        .all()
    )

    base_pay = 0.0
    holiday_bonus = 0.0
    overtime_hours = 0.0
    unauthorized_absences = 0

    for record in attendance_records:
        rec_date = record.date
        is_workday = is_work_day(rec_date)

        if record.time_in and record.time_out:
            try:
                in_time = dt.strptime(record.time_in, "%H:%M")
                out_time = dt.strptime(record.time_out, "%H:%M")
                total_seconds = (out_time - in_time).seconds
                hours_worked = total_seconds / 3600

                hours_worked = max(hours_worked - 1, 0)

                if rec_date in PUBLIC_HOLIDAYS:
                    holiday_bonus += hours_worked * hourly_rate * 2
                    continue

                regular_hours = min(hours_worked, 8)
                base_pay += regular_hours * hourly_rate

                if hours_worked > 8:
                    ot_hours = hours_worked - 8
                    overtime_hours += ot_hours
                    overtime_pay_ot = ot_hours * hourly_rate * overtime_rate_multiplier
                    overtime_pay += overtime_pay_ot

            except ValueError:
                if is_workday:
                    unauthorized_absences += 1

        elif record.status == "absent" and is_workday:
            unauthorized_absences += 1

        elif record.status == "overtime" and is_workday:
            ot_hours = 4
            overtime_hours += ot_hours
            overtime_pay += ot_hours * hourly_rate * overtime_rate_multiplier

    deductions = unauthorized_absences * (base_daily_salary * deduction_factor)

    final_salary = base_pay + overtime_pay + holiday_bonus - deductions
    final_salary = max(final_salary, 0)  # No negative salary

    return {
        "employee_id": employee.id,
        "name": employee.name,
        "department": employee.department,
        "base_monthly_salary": round(base_monthly_salary, 2),
        "work_days_in_month": work_days_in_month,
        "days_present_with_clock": sum(
            1 for r in attendance_records
            if r.time_in and r.time_out and is_work_day(r.date) and r.date not in PUBLIC_HOLIDAYS
        ),
        "holiday_bonus": round(holiday_bonus, 2),
        "overtime_hours": round(overtime_hours, 2),
        "overtime_pay": round(overtime_pay, 2),
        "unauthorized_absences": unauthorized_absences,
        "deductions": round(deductions, 2),
        "final_salary": round(final_salary, 2),
        "payment_date": (today.replace(day=5) + timedelta(days=30)).isoformat(),
        "status": "Calculated successfully",
        "calculation_date": today.isoformat()
    }