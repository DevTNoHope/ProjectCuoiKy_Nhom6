from pydantic import BaseModel
from typing import Optional, List

# 🟢 Schema tạo stylist
class StylistCreate(BaseModel):
    shop_id: int
    name: str
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: Optional[bool] = True
    service_ids: Optional[List[int]] = None  # danh sách dịch vụ stylist cung cấp

# 🟡 Schema cập nhật stylist
class StylistUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: Optional[bool] = None
    service_ids: Optional[List[int]] = None

# 🔵 Schema trả dữ liệu ra client
class StylistOut(BaseModel):
    id: int
    shop_id: int
    name: str
    bio: Optional[str]
    avatar_url: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True
