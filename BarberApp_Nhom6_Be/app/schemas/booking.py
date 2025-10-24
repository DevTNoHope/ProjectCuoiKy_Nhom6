from pydantic import BaseModel, Field, field_validator, field_serializer
from datetime import datetime, date, time, timezone
from decimal import Decimal
from typing import Optional, List
from enum import Enum

class BookingStatus(str, Enum):
    pending = "pending"
    approved = "approved"
    cancelled = "cancelled"
    completed = "completed"

# Dịch vụ trong booking
class BookingServiceIn(BaseModel):
    service_id: int
    price: Decimal
    duration_min: int

# Tạo booking mới (KHÔNG còn user_id)
class BookingCreate(BaseModel):
    shop_id: int
    stylist_id: Optional[int] = None
    start_dt: datetime
    end_dt: datetime
    total_price: Decimal
    note: Optional[str] = None
    services: List[BookingServiceIn]

    @field_validator("services")
    @classmethod
    def ensure_services_not_empty(cls, v):
        if not v:
            raise ValueError("At least one service is required")
        return v

# Cập nhật booking
class BookingUpdate(BaseModel):
    status: Optional[BookingStatus] = None
    shop_id: Optional[int] = None                # 🆕 thêm
    stylist_id: Optional[int] = None             # 🆕 thêm
    start_dt: Optional[datetime] = None
    end_dt: Optional[datetime] = None
    note: Optional[str] = None
    services: Optional[List[BookingServiceIn]] = None   # 🆕 thêm

# Trả ra client
class BookingOut(BaseModel):
    id: int
    user_id: int
    shop_id: int
    stylist_id: Optional[int]
    status: BookingStatus
    start_dt: datetime
    end_dt: datetime
    total_price: Decimal
    note: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
    @field_serializer("start_dt", "end_dt", when_used="json")
    def ser_dt(self, dt: datetime, _info):
        # Nếu DB vẫn lưu naive -> coi là UTC để trả ra đúng chuẩn
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        else:
            dt = dt.astimezone(timezone.utc)
        # isoformat() -> 'YYYY-MM-DDTHH:MM:SS+00:00', đổi về 'Z' cho gọn
        return dt.isoformat().replace("+00:00", "Z")