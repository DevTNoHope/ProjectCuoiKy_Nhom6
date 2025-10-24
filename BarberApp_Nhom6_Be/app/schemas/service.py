from pydantic import BaseModel
from typing import Optional
from decimal import Decimal

# 🟢 Schema tạo mới dịch vụ
class ServiceCreate(BaseModel):
    name: str
    description: Optional[str] = None
    duration_min: Optional[int] = 30
    price: Optional[Decimal] = 0
    is_active: Optional[bool] = True

# 🟡 Schema cập nhật dịch vụ
class ServiceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    duration_min: Optional[int] = None
    price: Optional[Decimal] = None
    is_active: Optional[bool] = None

# 🔵 Schema trả dữ liệu ra client
class ServiceOut(BaseModel):
    id: int
    name: str
    description: Optional[str]
    duration_min: int
    price: Decimal
    is_active: bool

    class Config:
        from_attributes = True
