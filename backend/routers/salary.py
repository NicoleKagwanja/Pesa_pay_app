from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, date
from pydantic import BaseModel
from database import get_db
from models import Attendance, Employee

router = APIRouter(tags=["salary"])

class SalaryCalculationRequest(BaseModel):
    employee_email: str
    month: str  
    hourly_rate: float = 500.0 

class SalaryResponse(BaseModel):
    employee_email: str
    month: str
    total_hours: float
    hourly_rate: float
    gross_salary: float
    deductions: float
    net_salary: float
    breakdown: dict

@router.post("/salary/calculate", response_model=SalaryResponse, operation_id="calculate_employee_salary")
def calculate_salary(request: SalaryCalculationRequest, db: Session = Depends(get_db)):

    try:
        year, month = map(int, request.month.split('-'))
        month_start = date(year, month, 1)
        if month == 12:
            month_end = date(year + 1, 1, 1)
        else:
            month_end = date(year, month + 1, 1)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid month format. Use YYYY-MM")
    
    records = db.query(Attendance).filter(
        Attendance.employee_email == request.employee_email,
        Attendance.date >= month_start,
        Attendance.date < month_end,
        Attendance.time_in != None, 
    ).all()
    
    total_hours = 0.0
    for record in records:
        if record.total_hours is not None:
            total_hours += record.total_hours
        elif record.time_in and record.time_out:
            try:
                from datetime import datetime, timedelta
                time_in = datetime.strptime(record.time_in, "%H:%M")
                time_out = datetime.strptime(record.time_out, "%H:%M")
                if time_out < time_in:
                    time_out += timedelta(days=1)
                hours = (time_out - time_in).seconds / 3600
                total_hours += hours
            except:
                pass 
    
    hourly_rate = request.hourly_rate
    gross_salary = round(total_hours * hourly_rate, 2)
    deduction_rate = 0.10
    deductions = round(gross_salary * deduction_rate, 2)
    net_salary = round(gross_salary - deductions, 2)
    
    return SalaryResponse(
        employee_email=request.employee_email,
        month=request.month,
        total_hours=round(total_hours, 2),
        hourly_rate=hourly_rate,
        gross_salary=gross_salary,
        deductions=deductions,
        net_salary=net_salary,
        breakdown={
            "base_calculation": f"{total_hours:.2f} hrs × KES {hourly_rate}/hr",
            "deduction_rate": f"{deduction_rate * 100}%",
            "deduction_items": ["NHIF", "NSSF", "PAYE (estimated)"],
        }
    )

@router.get("/salary/history/{email}", operation_id="get_salary_history")
def get_salary_history(email: str, limit: int = 6, db: Session = Depends(get_db)):
    from datetime import timedelta
    
    history = []
    today = date.today()
    
    for i in range(limit):
        if today.month - i <= 0:
            calc_year = today.year - 1
            calc_month = 12 + (today.month - i)
        else:
            calc_year = today.year
            calc_month = today.month - i
        
        month_str = f"{calc_year}-{str(calc_month).zfill(2)}"
        
        month_start = date(calc_year, calc_month, 1)
        month_end = date(calc_year, calc_month + 1, 1) if calc_month < 12 else date(calc_year + 1, 1, 1)
        
        records = db.query(Attendance).filter(
            Attendance.employee_email == email,
            Attendance.date >= month_start,
            Attendance.date < month_end,
        ).all()
        
        total_hours = sum(r.total_hours for r in records if r.total_hours)
        hourly_rate = 500.0
        gross = round(total_hours * hourly_rate, 2)
        deductions = round(gross * 0.10, 2)
        net = round(gross - deductions, 2)
        
        history.append({
            "month": month_str,
            "total_hours": round(total_hours, 2),
            "gross_salary": gross,
            "net_salary": net,
        })
    
    return {
        "employee_email": email,
        "currency": "KES",
        "hourly_rate": 500.0,
        "history": history
    }