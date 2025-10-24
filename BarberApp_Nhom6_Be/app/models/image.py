from __future__ import annotations
from sqlalchemy import Integer, String, DateTime, Enum, JSON
from sqlalchemy.orm import Mapped, mapped_column
from datetime import datetime
from app.models.base import Base

class Image(Base):
    __tablename__ = "images"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    entity_type: Mapped[str] = mapped_column(
        Enum("user", "shop", "service", "stylist", "booking", "ai_result")
    )
    entity_id: Mapped[int]
    url: Mapped[str] = mapped_column(String(255))
    meta_json: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime | None] = mapped_column(DateTime, default=datetime.utcnow)
