from __future__ import annotations
from sqlalchemy import Integer, String, Time, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import time
from app.models.base import Base

class WorkSchedule(Base):
    __tablename__ = "work_schedules"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    stylist_id: Mapped[int] = mapped_column(ForeignKey("stylists.id", ondelete="CASCADE"))
    weekday: Mapped[str] = mapped_column(String(3))  # 'Mon'...'Sun'
    start_time: Mapped[time] = mapped_column(Time)
    end_time: Mapped[time] = mapped_column(Time)

    stylist: Mapped["Stylist"] = relationship(back_populates="schedules")
