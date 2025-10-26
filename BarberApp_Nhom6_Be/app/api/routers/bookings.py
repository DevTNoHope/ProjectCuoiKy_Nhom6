from fastapi import APIRouter, Depends, HTTPException, status, Query, BackgroundTasks
from datetime import datetime, date, time, timezone
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.core.deps import get_db
from app.core.auth_deps import admin_required, get_current_user
from app.models.booking import Booking, BookingService
from app.models.stylist import Stylist
from app.models.user import User
from app.models.shop import Shop  # để lấy tên shop
from app.schemas.booking import BookingOut, BookingCreate, BookingUpdate, BookingStatus
from app.core.mailer import send_booking_email  # 🟢 module gửi email

router = APIRouter(prefix="/bookings", tags=["bookings"])


# ------------------------------
# 🕒 Hàm hỗ trợ chuyển datetime sang UTC
# ------------------------------
def _to_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


# ------------------------------
# 1️⃣ Danh sách toàn bộ booking (Admin)
# ------------------------------
@router.get("", response_model=list[BookingOut], dependencies=[Depends(admin_required)])
def list_bookings(db: Session = Depends(get_db)):
    return db.query(Booking).order_by(Booking.id.desc()).all()


# ------------------------------
# 2️⃣ Lấy danh sách booking của chính user (JWT)
# ------------------------------
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


# ------------------------------
# 3️⃣ Lấy booking theo user_id (Admin)
# ------------------------------
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


# ------------------------------
# 4️⃣ Tạo mới booking
# ------------------------------
@router.post("", response_model=BookingOut, status_code=status.HTTP_201_CREATED)
def create_booking(
    payload: BookingCreate,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
    background_tasks: BackgroundTasks = None,  # ✅ thêm để gửi email nền
):
    """
    - User bình thường → booking gán user_id = me.id
    - Admin → có thể truyền user_id để đặt thay người khác
    """
    user_id = payload.user_id if getattr(me, "role", "").lower() == "admin" and payload.user_id else me.id

    # 🔍 Kiểm tra stylist tồn tại
    if payload.stylist_id:
        stylist = db.query(Stylist).filter(Stylist.id == payload.stylist_id).first()
        if not stylist:
            raise HTTPException(status_code=404, detail="Stylist not found")

        # ⛔ Kiểm tra trùng giờ
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

    # 🟢 Tạo booking
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
    db.flush()  # lấy id

    # ➕ Thêm các dịch vụ
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

    # ------------------------------
    # ✉️ GỬI EMAIL XÁC NHẬN
    # ------------------------------
    user = db.query(User).filter(User.id == user_id).first()
    shop = db.query(Shop).filter(Shop.id == payload.shop_id).first()

    if user and user.email:
        background_tasks.add_task(
            send_booking_email,
            to_email=user.email,
            customer_name=user.full_name,
            booking_info={
                "shop_name": shop.name if shop else "Không xác định",
                "start_dt": booking.start_dt.strftime("%H:%M %d/%m/%Y"),
                "end_dt": booking.end_dt.strftime("%H:%M %d/%m/%Y"),
                "total_price": float(booking.total_price),
            },
        )

    return booking


# ------------------------------
# 5️⃣ Cập nhật booking
# ------------------------------
@router.put("/{booking_id}", response_model=BookingOut)
def update_booking(booking_id: int, payload: BookingUpdate, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    # 🔁 Nếu đổi giờ → kiểm tra trùng
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

    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(booking, key, value)

    db.commit()
    db.refresh(booking)
    return booking


# ------------------------------
# 6️⃣ Xoá booking (Admin)
# ------------------------------
@router.delete("/{booking_id}", dependencies=[Depends(admin_required)])
def delete_booking(booking_id: int, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    db.delete(booking)
    db.commit()
    return {"message": "Deleted successfully"}


# ------------------------------
# 7️⃣ Lấy lịch làm việc của stylist trong ngày
# ------------------------------
@router.get("/stylist/{stylist_id}", response_model=list[BookingOut])
def get_stylist_bookings_by_day(
    stylist_id: int,
    day: date = Query(..., alias="date"),
    db: Session = Depends(get_db),
    me=Depends(get_current_user),
):
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
