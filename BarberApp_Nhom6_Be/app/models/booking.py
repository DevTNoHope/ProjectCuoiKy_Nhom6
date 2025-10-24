from __future__ import annotations
from sqlalchemy import Integer, String, Text, DateTime, DECIMAL, Boolean, Enum, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from decimal import Decimal
from datetime import datetime
from app.models.base import Base
import enum

class BookingStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    cancelled = "cancelled"
    completed = "completed"

class Booking(Base):
    __tablename__ = "bookings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    shop_id: Mapped[int] = mapped_column(ForeignKey("shops.id", ondelete="CASCADE"))
    stylist_id: Mapped[int | None] = mapped_column(ForeignKey("stylists.id", ondelete="SET NULL"))
    status: Mapped[BookingStatus] = mapped_column(Enum(BookingStatus), default=BookingStatus.pending)
    start_dt: Mapped[datetime] = mapped_column(DateTime)
    end_dt: Mapped[datetime] = mapped_column(DateTime)
    total_price: Mapped[Decimal] = mapped_column(DECIMAL(10, 2), default=0)
    note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime | None] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="bookings")
    shop: Mapped["Shop"] = relationship(back_populates="bookings")
    stylist: Mapped["Stylist"] = relationship(back_populates="bookings")

    services: Mapped[list["BookingService"]] = relationship(back_populates="booking", cascade="all, delete-orphan")
    reviews: Mapped[list["Review"]] = relationship(back_populates="booking")
    messages: Mapped[list["ChatMessage"]] = relationship(back_populates="booking")


class BookingService(Base):
    __tablename__ = "booking_services"

    booking_id: Mapped[int] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"), primary_key=True
    )
    service_id: Mapped[int] = mapped_column(
        ForeignKey("services.id", ondelete="CASCADE"), primary_key=True
    )
    price: Mapped[Decimal] = mapped_column(DECIMAL(10, 2), default=0)
    duration_min: Mapped[int] = mapped_column(Integer, default=30)

    booking: Mapped["Booking"] = relationship(back_populates="services")
    service: Mapped["Service"] = relationship(back_populates="booking_links")
