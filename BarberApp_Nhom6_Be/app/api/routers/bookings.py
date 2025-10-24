from fastapi import APIRouter, Depends, HTTPException, status, Query
from datetime import datetime, date, time, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.core.deps import get_db
from app.core.auth_deps import admin_required, get_current_user
from app.models.booking import Booking, BookingService
from app.models.stylist import Stylist
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
@router.get("/user/{user_id}", response_model=list[BookingOut], dependencies=[Depends(admin_required)])
def list_user_bookings(user_id: int, db: Session = Depends(get_db)):
    return (
        db.query(Booking)
        .filter(Booking.user_id == user_id)
        .order_by(Booking.start_dt.desc())
        .all()
    )

# 3. Tạo mới booking (User) - lấy user từ JWT
@router.post("", response_model=BookingOut, status_code=status.HTTP_201_CREATED)
def create_booking(
    payload: BookingCreate,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
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

    # (Tuỳ chọn) bạn có thể tự tính total_price từ services nếu muốn “server-authoritative”
    # total_calc = sum(s.price for s in payload.services)
    # if total_calc != payload.total_price:
    #     raise HTTPException(status_code=400, detail="total_price mismatch")
    start_utc = _to_utc(payload.start_dt)
    end_utc   = _to_utc(payload.end_dt)

    # Tạo booking mới (user_id lấy từ JWT)
    booking = Booking(
        user_id=me.id,
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

    # 🆕 Nếu đổi shop hoặc stylist → kiểm tra tồn tại
    if payload.shop_id:
        from app.models.shop import Shop
        shop = db.query(Shop).filter(Shop.id == payload.shop_id).first()
        if not shop:
            raise HTTPException(status_code=404, detail="Shop not found")
        booking.shop_id = payload.shop_id

    if payload.stylist_id:
        stylist = db.query(Stylist).filter(Stylist.id == payload.stylist_id).first()
        if not stylist:
            raise HTTPException(status_code=404, detail="Stylist not found")
        booking.stylist_id = payload.stylist_id

    # 🆕 Nếu đổi lịch → kiểm tra trùng giờ stylist
    if payload.start_dt and (payload.stylist_id or booking.stylist_id):
        stylist_id = payload.stylist_id or booking.stylist_id
        conflict = (
            db.query(Booking)
            .filter(
                and_(
                    Booking.stylist_id == stylist_id,
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
    # 🆕 Tính lại tổng giá và thời gian
    if payload.services is not None and payload.services:
        total_price = sum(s.price for s in payload.services if s.price)
        total_minutes = sum(s.duration_min for s in payload.services if s.duration_min)
        booking.total_price = total_price

        # end_dt = start_dt + tổng thời lượng (phút)
        if booking.start_dt:
            booking.end_dt = booking.start_dt + timedelta(minutes=total_minutes)

    

    # 🆕 Cập nhật dịch vụ (nếu có truyền services mới)
    if payload.services is not None:
        # Xoá dịch vụ cũ
        db.query(BookingService).filter(BookingService.booking_id == booking.id).delete()
        # Thêm lại dịch vụ mới
        for s in payload.services:
            db.add(
                BookingService(
                    booking_id=booking.id,
                    service_id=s.service_id,
                    price=s.price,
                    duration_min=s.duration_min,
                )
            )
        

    # 🟩 Cập nhật các trường cơ bản khác
    for key, value in payload.model_dump(exclude_unset=True, exclude={"services", "shop_id", "stylist_id"}).items():
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
@router.get("/stylist/{stylist_id}", response_model=list[BookingOut])
def get_stylist_bookings_by_day(
    stylist_id: int,
    day: date = Query(..., alias="date"),   # nhận 'date=YYYY-MM-DD'
    db: Session = Depends(get_db),
    me=Depends(get_current_user),           # chỉ cần user đăng nhập
):
    # khoảng thời gian trong ngày theo UTC
    start = datetime.combine(day, time.min).replace(tzinfo=timezone.utc)
    end   = datetime.combine(day, time.max).replace(tzinfo=timezone.utc)

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
# 6️⃣ User tự xoá booking của mình
@router.delete("/me/{booking_id}")
def delete_my_booking(
    booking_id: int,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.user_id != me.id:
        raise HTTPException(status_code=403, detail="You can only delete your own bookings")
    if booking.status not in [BookingStatus.pending, BookingStatus.approved]:
        raise HTTPException(status_code=400, detail="Cannot delete a completed or cancelled booking")

    db.delete(booking)
    db.commit()
    return {"message": "Booking deleted successfully"}
    
@router.get("/{booking_id}")
def get_booking_detail(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    booking = (
        db.query(Booking)
        .filter(Booking.id == booking_id)
        .first()
    )
    if not booking:
        raise HTTPException(status_code=404, detail="Không tìm thấy lịch đặt")

    # ✅ Kiểm tra quyền truy cập
    if booking.user_id != current_user.id and current_user.role != "Admin":
        raise HTTPException(status_code=403, detail="Không có quyền truy cập lịch này")

    # ✅ Gộp dịch vụ đã chọn vào response
    services = (
        db.query(BookingService.service_id, BookingService.price, BookingService.duration_min)
        .filter(BookingService.booking_id == booking_id)
        .all()
    )

    booking_data = {
        **booking.__dict__,
        "services": [dict(s._mapping) for s in services],  # 🆕 thêm vào JSON trả ra
    }

    return booking_data

