# app/schemas/notification.py
from typing import Optional
from datetime import datetime
from pydantic import BaseModel

class NotificationOut(BaseModel):
    id: int
    title: str
    body: str
    data_json: Optional[str] = None
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
