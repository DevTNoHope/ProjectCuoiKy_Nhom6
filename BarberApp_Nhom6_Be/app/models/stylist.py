from __future__ import annotations
from sqlalchemy import Integer, String, Text, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.models.base import Base

class Stylist(Base):
    __tablename__ = "stylists"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    shop_id: Mapped[int] = mapped_column(ForeignKey("shops.id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(100))
    bio: Mapped[str | None] = mapped_column(Text)
    avatar_url: Mapped[str | None] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    shop: Mapped["Shop"] = relationship(back_populates="stylists")
    services: Mapped[list["StylistService"]] = relationship(back_populates="stylist")
    schedules: Mapped[list["WorkSchedule"]] = relationship(back_populates="stylist")
    bookings: Mapped[list["Booking"]] = relationship(back_populates="stylist")


class StylistService(Base):
    __tablename__ = "stylist_services"

    stylist_id: Mapped[int] = mapped_column(
        ForeignKey("stylists.id", ondelete="CASCADE"), primary_key=True
    )
    service_id: Mapped[int] = mapped_column(
        ForeignKey("services.id", ondelete="CASCADE"), primary_key=True
    )

    stylist: Mapped["Stylist"] = relationship(back_populates="services")
    service: Mapped["Service"] = relationship(back_populates="stylist_links")
