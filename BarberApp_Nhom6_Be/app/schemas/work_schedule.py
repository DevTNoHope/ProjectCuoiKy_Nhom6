from pydantic import BaseModel, Field
from datetime import time
from typing import Optional

# 🟢 Schema tạo mới ca làm
class WorkScheduleCreate(BaseModel):
    stylist_id: int
    weekday: str = Field(..., example="Mon")
    start_time: time
    end_time: time

# 🟡 Schema cập nhật ca làm
class WorkScheduleUpdate(BaseModel):
    weekday: Optional[str] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None

# 🔵 Schema trả dữ liệu ra client
class WorkScheduleOut(BaseModel):
    id: int
    stylist_id: int
    weekday: str
    start_time: time
    end_time: time

    class Config:
        from_attributes = True
