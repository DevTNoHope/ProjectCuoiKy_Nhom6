from __future__ import annotations
from sqlalchemy import Integer, String, Boolean, DateTime, Time, DECIMAL
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, time
from decimal import Decimal
from app.models.base import Base

class Shop(Base):
    __tablename__ = "shops"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100))
    address: Mapped[str] = mapped_column(String(255))
    lat: Mapped[Decimal | None] = mapped_column(DECIMAL(10, 6))
    lng: Mapped[Decimal | None] = mapped_column(DECIMAL(10, 6))
    phone: Mapped[str | None] = mapped_column(String(20))
    open_time: Mapped[time | None] = mapped_column(Time)
    close_time: Mapped[time | None] = mapped_column(Time)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime | None] = mapped_column(DateTime, default=datetime.utcnow)

    stylists: Mapped[list["Stylist"]] = relationship(back_populates="shop")
    bookings: Mapped[list["Booking"]] = relationship(back_populates="shop")
