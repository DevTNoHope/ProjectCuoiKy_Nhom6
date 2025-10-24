from __future__ import annotations
from sqlalchemy import Integer, String, Text, Boolean, DECIMAL
from sqlalchemy.orm import Mapped, mapped_column, relationship
from decimal import Decimal
from app.models.base import Base

class Service(Base):
    __tablename__ = "services"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100))
    description: Mapped[str | None] = mapped_column(Text)
    duration_min: Mapped[int] = mapped_column(Integer, default=30)
    price: Mapped[Decimal] = mapped_column(DECIMAL(10, 2), default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    stylist_links: Mapped[list["StylistService"]] = relationship(back_populates="service")
    booking_links: Mapped[list["BookingService"]] = relationship(back_populates="service")
