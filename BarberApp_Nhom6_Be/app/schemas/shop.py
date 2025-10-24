from pydantic import BaseModel
from datetime import time
from typing import Optional

# 🟢 Schema để tạo shop (input khi POST)
class ShopCreate(BaseModel):
    name: str
    address: str
    phone: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    open_time: Optional[time] = None
    close_time: Optional[time] = None

# 🟡 Schema để cập nhật shop (input khi PUT)
class ShopUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    open_time: Optional[time] = None
    close_time: Optional[time] = None
    is_active: Optional[bool] = None

# 🔵 Schema để trả ra client (output)
class ShopOut(BaseModel):
    id: int
    name: str
    address: str
    lat: float | None = None
    lng: float | None = None
    phone: str | None = None
    is_active: bool

    class Config:
        from_attributes = True
