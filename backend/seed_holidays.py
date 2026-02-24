from sqlalchemy.orm import Session
from datetime import date
from database import SessionLocal, engine, Base
from models import PublicHoliday

KENYA_HOLIDAYS = [
    {"name": "New Year's Day",           "date": date(2025, 1, 1)},
    {"name": "Good Friday",              "date": date(2025, 4, 18)},
    {"name": "Easter Monday",            "date": date(2025, 4, 21)},
    {"name": "Labour Day",               "date": date(2025, 5, 1)},
    {"name": "Madaraka Day",             "date": date(2025, 6, 1)},
    {"name": "Huduma Day",               "date": date(2025, 10, 10)},
    {"name": "Mashujaa Day",             "date": date(2025, 10, 20)},
    {"name": "Independence Day",         "date": date(2025, 12, 12)},
    {"name": "Christmas Day",            "date": date(2025, 12, 25)},
    {"name": "Boxing Day",               "date": date(2025, 12, 26)},
]

def seed_holidays():
    db = SessionLocal()
    try:
        for holiday_data in KENYA_HOLIDAYS:
            existing = db.query(PublicHoliday).filter(PublicHoliday.date == holiday_data["date"]).first()
            if not existing:
                holiday = PublicHoliday(**holiday_data)
                db.add(holiday)
                print(f"Added: {holiday_data['name']} on {holiday_data['date']}")
            else:
                print(f"Already exists: {holiday_data['name']} on {holiday_data['date']}")
        db.commit()
        print("\nAll holidays seeded successfully!")
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
    seed_holidays()