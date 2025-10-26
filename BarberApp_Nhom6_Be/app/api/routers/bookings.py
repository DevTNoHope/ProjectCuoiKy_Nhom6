from fastapi import APIRouter, Depends, HTTPException, status, Query
from datetime import datetime, date, time, timezone, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.core.deps import get_db
from app.core.auth_deps import admin_required, get_current_user
from app.models.booking import Booking, BookingService
from app.models.stylist import Stylist
from app.models.schedule import WorkSchedule   # ✅ thêm import này
from app.models.user import User
from app.schemas.booking import BookingOut, BookingCreate, BookingUpdate, BookingStatus


router = APIRouter(prefix="/bookings", tags=["bookings"])


def _to_utc(dt: datetime) -> datetime:
    # nhận từ Pydantic: có thể tz-aware (có Z) hoặc naive
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)  # coi naive là UTC
    return dt.astimezone(timezone.utc)


# 1. Danh sách toàn bộ booking (Admin)
@router.get("", response_model=list[BookingOut], dependencies=[Depends(admin_required)])
def list_bookings(db: Session = Depends(get_db)):
    return db.query(Booking).order_by(Booking.id.desc()).all()


# 2a. Lấy booking của chính mình (JWT)
@router.get("/me", response_model=list[BookingOut])
def list_my_bookings(
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    return (
        db.query(Booking)
        .filter(Booking.user_id == me.id)
        .order_by(Booking.start_dt.desc())
        .all()
    )


# (Giữ nguyên) 2b. Lấy booking theo user_id (nếu bạn vẫn muốn API này cho admin/CSKH)
@router.get(
    "/user/{user_id}",
    response_model=list[BookingOut],
    dependencies=[Depends(admin_required)],
)
def list_user_bookings(user_id: int, db: Session = Depends(get_db)):
    return (
        db.query(Booking)
        .filter(Booking.user_id == user_id)
        .order_by(Booking.start_dt.desc())
        .all()
    )


# ✅ 3. Tạo mới booking (User hoặc Admin)
@router.post("", response_model=BookingOut, status_code=status.HTTP_201_CREATED)
def create_booking(
    payload: BookingCreate,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    """
    - User bình thường → booking gán user_id = me.id
    - Admin → có thể truyền user_id để đặt thay người khác
    """
    user_id = payload.user_id if getattr(me, "role", "").lower() == "admin" and payload.user_id else me.id

    # Kiểm tra stylist tồn tại (nếu có chọn)
    if payload.stylist_id:
        stylist = db.query(Stylist).filter(Stylist.id == payload.stylist_id).first()
        if not stylist:
            raise HTTPException(status_code=404, detail="Stylist not found")

        # Kiểm tra trùng lịch stylist
        conflict = (
            db.query(Booking)
            .filter(
                and_(
                    Booking.stylist_id == payload.stylist_id,
                    Booking.status.in_([BookingStatus.pending, BookingStatus.approved]),
                    Booking.start_dt < payload.end_dt,
                    Booking.end_dt > payload.start_dt,
                )
            )
            .first()
        )
        if conflict:
            raise HTTPException(
                status_code=400,
                detail="Stylist already has a booking in this time range",
            )

    start_utc = _to_utc(payload.start_dt)
    end_utc = _to_utc(payload.end_dt)

    # 🟢 Tạo booking (với user_id đúng)
    booking = Booking(
        user_id=user_id,
        shop_id=payload.shop_id,
        stylist_id=payload.stylist_id,
        start_dt=start_utc,
        end_dt=end_utc,
        total_price=payload.total_price,
        note=payload.note,
    )

    db.add(booking)
    db.flush()  # lấy booking.id trước khi thêm services

    # Thêm các dịch vụ
    for s in payload.services:
        db.add(
            BookingService(
                booking_id=booking.id,
                service_id=s.service_id,
                price=s.price,
                duration_min=s.duration_min,
            )
        )

    db.commit()
    db.refresh(booking)
    return booking


# 4. Cập nhật booking (duyệt / hủy / đổi lịch)
@router.put("/{booking_id}", response_model=BookingOut)
def update_booking(booking_id: int, payload: BookingUpdate, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Nếu đổi lịch → kiểm tra trùng giờ stylist (nếu booking có stylist)
    if payload.start_dt and booking.stylist_id:
        conflict = (
            db.query(Booking)
            .filter(
                and_(
                    Booking.stylist_id == booking.stylist_id,
                    Booking.id != booking_id,
                    Booking.status.in_([BookingStatus.pending, BookingStatus.approved]),
                    Booking.start_dt < (payload.end_dt or booking.end_dt),
                    Booking.end_dt > payload.start_dt,
                )
            )
            .first()
        )
        if conflict:
            raise HTTPException(
                status_code=400,
                detail="Stylist already booked in this new time range",
            )

    # Cập nhật trường cho phép
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(booking, key, value)

    db.commit()
    db.refresh(booking)
    return booking


# 5. Xoá booking (Admin)
@router.delete("/{booking_id}", dependencies=[Depends(admin_required)])
def delete_booking(booking_id: int, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    db.delete(booking)
    db.commit()
    return {"message": "Deleted successfully"}


# 6. Lấy lịch làm việc của stylist trong ngày
@router.get("/stylist/{stylist_id}", response_model=list[BookingOut])
def get_stylist_bookings_by_day(
    stylist_id: int,
    day: date = Query(..., alias="date"),   # nhận 'date=YYYY-MM-DD'
    db: Session = Depends(get_db),
    me=Depends(get_current_user),           # chỉ cần user đăng nhập
):
    # khoảng thời gian trong ngày theo UTC
    start = datetime.combine(day, time.min).replace(tzinfo=timezone.utc)
    end = datetime.combine(day, time.max).replace(tzinfo=timezone.utc)

    return (
        db.query(Booking)
        .filter(
            and_(
                Booking.stylist_id == stylist_id,
                Booking.status.in_([BookingStatus.pending, BookingStatus.approved]),
                Booking.start_dt < end,
                Booking.end_dt > start,
            )
        )
        .order_by(Booking.start_dt.asc())
        .all()
    )


# ✅ 7. Trả về danh sách giờ TRỐNG của stylist trong ngày
@router.get("/stylist/{stylist_id}/available")
def get_stylist_available_slots(
    stylist_id: int,
    day: date = Query(..., alias="date"),  # ví dụ ?date=2025-10-25
    db: Session = Depends(get_db),
):
    """
    Trả về danh sách các khoảng giờ trống của stylist trong ngày (dựa trên ca làm và booking hiện có)
    """
    # 1️⃣ Lấy ca làm theo thứ
    weekday_str = day.strftime("%a")[:3]  # Mon/Tue/Wed...
    schedule = (
        db.query(WorkSchedule)
        .filter(
            WorkSchedule.stylist_id == stylist_id,
            WorkSchedule.weekday == weekday_str,
        )
        .first()
    )
    if not schedule:
        return []  # stylist nghỉ ngày này

    # 2️⃣ Lấy tất cả booking đã chiếm chỗ trong ngày
    start_day = datetime.combine(day, time.min).replace(tzinfo=timezone.utc)
    end_day = datetime.combine(day, time.max).replace(tzinfo=timezone.utc)
    bookings = (
        db.query(Booking)
        .filter(
            Booking.stylist_id == stylist_id,
            Booking.status.in_([BookingStatus.pending, BookingStatus.approved]),
            Booking.start_dt < end_day,
            Booking.end_dt > start_day,
        )
        .order_by(Booking.start_dt.asc())
        .all()
    )

    # 3️⃣ Tạo danh sách slot rảnh dựa trên ca làm và booking
    available = []
    current = datetime.combine(day, schedule.start_time).replace(tzinfo=timezone.utc)
    work_end = datetime.combine(day, schedule.end_time).replace(tzinfo=timezone.utc)

    for b in bookings:
        if current < b.start_dt:
            available.append({
                "start": current.isoformat().replace("+00:00", "Z"),
                "end": b.start_dt.isoformat().replace("+00:00", "Z"),
            })
        current = max(current, b.end_dt)

    if current < work_end:
        available.append({
            "start": current.isoformat().replace("+00:00", "Z"),
            "end": work_end.isoformat().replace("+00:00", "Z"),
        })

    return available
