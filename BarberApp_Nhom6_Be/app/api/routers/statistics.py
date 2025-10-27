from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, extract, desc
from datetime import datetime, timedelta

from app.core.deps import get_db
from app.core.auth_deps import admin_required
from app.models.booking import Booking, BookingService
from app.models.service import Service
from app.models.stylist import Stylist
from app.models.shop import Shop

router = APIRouter(prefix="/statistics", tags=["statistics"], dependencies=[Depends(admin_required)])


# 🟢 1. Booking theo tháng (12 tháng gần nhất)
@router.get("/bookings/monthly")
def bookings_by_month(db: Session = Depends(get_db)):
    result = (
        db.query(
            extract("month", Booking.start_dt).label("month"),
            func.count(Booking.id).label("count")
        )
        .group_by(extract("month", Booking.start_dt))
        .order_by(extract("month", Booking.start_dt))
        .all()
    )
    return [{"month": int(r.month), "count": r.count} for r in result]


# 🟢 2. Booking theo ngày (7 ngày gần nhất)
@router.get("/bookings/daily")
def bookings_by_day(db: Session = Depends(get_db)):
    today = datetime.utcnow().date()
    seven_days_ago = today - timedelta(days=6)

    result = (
        db.query(
            func.date(Booking.start_dt).label("date"),
            func.count(Booking.id).label("count")
        )
        .filter(func.date(Booking.start_dt) >= seven_days_ago)
        .group_by(func.date(Booking.start_dt))
        .order_by(func.date(Booking.start_dt))
        .all()
    )
    return [{"date": r.date.isoformat(), "count": r.count} for r in result]


# 🟢 3. Dịch vụ được đặt nhiều nhất
@router.get("/top-services")
def top_services(db: Session = Depends(get_db)):
    result = (
        db.query(Service.name, func.count(BookingService.service_id).label("count"))
        .join(Service, Service.id == BookingService.service_id)
        .group_by(Service.name)
        .order_by(desc("count"))
        .limit(5)
        .all()
    )
    return [{"service_name": r.name, "count": r.count} for r in result]


# 🟢 4. Tổng số stylist, shop, booking
@router.get("/summary")
def summary_counts(db: Session = Depends(get_db)):
    total_stylists = db.query(func.count(Stylist.id)).scalar()
    total_shops = db.query(func.count(Shop.id)).scalar()
    total_bookings = db.query(func.count(Booking.id)).scalar()

    return {
        "stylists": total_stylists,
        "shops": total_shops,
        "bookings": total_bookings,
    }
