from fastapi import APIRouter, Depends, HTTPException, status, Query
from datetime import datetime, date, time, timezone
from sqlalchemy.orm import Session
from sqlalchemy import and_, text   # ⬅️ thêm text
import json                         # ⬅️ thêm json
from app.core.deps import get_db
from app.core.auth_deps import admin_required, get_current_user
from app.models.booking import Booking, BookingService
from app.models.stylist import Stylist
from app.models.user import User, UserRole
from app.schemas.booking import BookingOut, BookingCreate, BookingUpdate, BookingStatus
# ==== THÊM IMPORT CHO THÔNG BÁO ====
from app.models.shop import Shop
from app.models.device import Device
from app.core.onesignal import onesignal

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
   # ============================================================
    # 🔔 GỬI THÔNG BÁO CHO USER (KHÁCH HÀNG)
    # ============================================================
    # đặt mặc định để tránh lỗi biến chưa gán nếu query shop lỗi
    shop_name = "Cửa hàng"
    shop_address = ""

   # lấy thông tin cửa hàng (không để lỗi ảnh hưởng flow)
    try:
        shop = db.query(Shop).filter(Shop.id == payload.shop_id).first()
        if shop:
            if getattr(shop, "name", None):
                shop_name = shop.name
            if getattr(shop, "address", None):
                shop_address = shop.address or ""
    except Exception as _:
        pass

    try:
        # Lấy danh sách OneSignal Player ID của user hiện tại
        player_ids = [
            d.onesignal_player_id
            for d in db.query(Device).filter(Device.user_id == me.id).all()
            if d.onesignal_player_id
        ]

        # Gửi thông báo OneSignal cho User
        if player_ids:
            when_str = booking.start_dt.astimezone(timezone.utc).strftime('%H:%M %d/%m/%Y')
            onesignal.send_to_players(
                player_ids=player_ids,
                title_vi="Đặt lịch thành công 🎉",
                body_vi=f"{when_str} tại {shop_name} - {shop_address}",
                data={"bookingId": str(booking.id), "screen": "BookingDetail"},
            )
    except Exception as e:
        # không làm hỏng flow nếu push lỗi
        print(f"Lỗi gửi thông báo OneSignal (user): {e}")

    # ============================================================
    # 🔔 GỬI THÔNG BÁO CHO ADMIN (khi có booking mới)
    # ============================================================
    try:
        # Lấy tất cả thiết bị của tài khoản có role = Admin
        admin_devices = (
            db.query(Device)
            .join(User, User.id == Device.user_id)
            .filter(User.role == UserRole.Admin)
            .all()
        )
        admin_player_ids = [
            d.onesignal_player_id for d in admin_devices if d.onesignal_player_id
        ]

        if admin_player_ids:
            title = "Đặt lịch hẹn mới"
            when_str = booking.start_dt.astimezone(timezone.utc).strftime('%H:%M %d/%m/%Y')
            content = f"Khách {me.full_name or 'Khách hàng'} đặt lịch tại {shop_name} lúc {when_str}"

            onesignal.send_to_players(
                player_ids=admin_player_ids,
                title_vi=title,
                body_vi=content,
                data={"bookingId": str(booking.id), "screen": "AdminBookingList"},
            )
    except Exception as e:
        print(f"Lỗi gửi thông báo OneSignal (admin): {e}")
 # (D) MỤC 5 — GHI LOG THÔNG BÁO VÀO DB (raw SQL, không cần model)
    try:
        # Log cho User (người đặt lịch)
        user_title = "Đặt lịch thành công 🎉"
        user_when  = booking.start_dt.astimezone(timezone.utc).strftime('%H:%M %d/%m/%Y')
        user_body  = f"{user_when} tại {shop_name} - {shop_address}"
        user_data  = json.dumps({"bookingId": booking.id, "screen": "BookingDetail"})
        db.execute(
            text("""
                INSERT INTO notifications (user_id, title, body, data_json)
                VALUES (:user_id, :title, :body, :data_json)
            """),
            {"user_id": me.id, "title": user_title, "body": user_body, "data_json": user_data}
        )

        # Log cho tất cả Admin
        admin_user_ids = [
            uid for (uid,) in
            db.query(User.id).filter(User.role == UserRole.Admin).all()
        ]
        if admin_user_ids:
            admin_title = "Đặt lịch hẹn mới"
            admin_when  = booking.start_dt.astimezone(timezone.utc).strftime('%H:%M %d/%m/%Y')
            admin_body  = f"Khách {me.full_name or 'Khách hàng'} đặt lịch tại {shop_name} lúc {admin_when}"
            admin_data  = json.dumps({"bookingId": booking.id, "screen": "AdminBookingList"})
            for admin_id in admin_user_ids:
                db.execute(
                    text("""
                        INSERT INTO notifications (user_id, title, body, data_json)
                        VALUES (:user_id, :title, :body, :data_json)
                    """),
                    {"user_id": admin_id, "title": admin_title, "body": admin_body, "data_json": admin_data}
                )

        db.commit()
    except Exception as e:
        # Không phá flow nếu log lỗi
        print(f"Lỗi ghi log notifications: {e}")
    # ============================================================
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