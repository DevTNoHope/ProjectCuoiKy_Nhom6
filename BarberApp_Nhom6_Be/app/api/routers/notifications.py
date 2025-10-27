# app/api/routers/notifications.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import select, update, delete
from typing import List, Optional

from app.core.deps import get_db
from app.core.auth_deps import get_current_user
from app.models.notification import Notification
from app.models.user import User
from app.schemas.notification import NotificationOut

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("/me", response_model=List[NotificationOut])
def list_my_notifications(
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
    unread_only: bool = Query(False, description="Chỉ lấy chưa đọc"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    stmt = select(Notification).where(Notification.user_id == me.id)
    if unread_only:
        stmt = stmt.where(Notification.is_read == False)  # noqa
    stmt = stmt.order_by(Notification.id.desc()).limit(limit).offset(offset)
    rows = db.execute(stmt).scalars().all()
    return rows

@router.post("/{notif_id}/read")
def mark_read(
    notif_id: int,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    n = db.get(Notification, notif_id)
    if not n or n.user_id != me.id:
        raise HTTPException(status_code=404, detail="Notification not found")
    if not n.is_read:
        n.is_read = True
        db.commit()
    return {"ok": True}

@router.post("/read-all")
def mark_all_read(
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    db.execute(
        update(Notification)
        .where(Notification.user_id == me.id, Notification.is_read == False)  # noqa
        .values(is_read=True)
    )
    db.commit()
    return {"ok": True}

@router.delete("/{notif_id}")
def delete_one(
    notif_id: int,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user),
):
    n = db.get(Notification, notif_id)
    if not n or n.user_id != me.id:
        raise HTTPException(status_code=404, detail="Notification not found")
    db.delete(n)
    db.commit()
    return {"ok": True}
