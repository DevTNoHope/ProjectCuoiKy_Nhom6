from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from app.core.deps import get_db
from app.core.auth_deps import admin_required
from app.models.user import User
from app.models.review import Review, ReviewReply
from app.core.auth_deps import get_current_user
from app.models.booking import Booking, BookingStatus
from app.schemas.review import (
    ReviewCreate, ReviewUpdate, ReviewOut,
    ReviewReplyCreate, ReviewReplyOut, ReviewWithReplies
)

router = APIRouter(prefix="/reviews", tags=["reviews"])


# ✅ 1. User tạo đánh giá sau khi hoàn thành booking
@router.post("", response_model=ReviewOut, status_code=status.HTTP_201_CREATED)
def create_review(payload: ReviewCreate, db: Session = Depends(get_db)):
    # Kiểm tra booking có tồn tại & đã hoàn thành chưa
    booking = db.query(Booking).filter(Booking.id == payload.booking_id).first()
    if not booking:
        raise HTTPException(404, "Booking not found")

    if booking.status != BookingStatus.completed:
        raise HTTPException(400, "You can only review after booking is completed")

    # Kiểm tra user có phải chủ booking không
    if booking.user_id != payload.user_id:
        raise HTTPException(403, "You can only review your own bookings")

    review = Review(**payload.dict())
    db.add(review)
    db.commit()
    db.refresh(review)
    return review


# ✅ 2. Lấy danh sách review (toàn bộ)
@router.get("", response_model=list[ReviewWithReplies])
def list_reviews(db: Session = Depends(get_db)):
    rows = (
        db.query(Review)
        .options(joinedload(Review.replies))
        .order_by(Review.id.desc())
        .all()
    )
    return rows


# ✅ 3. Lấy review theo stylist (thông qua booking)
@router.get("/stylist/{stylist_id}", response_model=list[ReviewWithReplies])
def list_reviews_by_stylist(stylist_id: int, db: Session = Depends(get_db)):
    rows = (
        db.query(Review)
        .join(Booking)
        .filter(Booking.stylist_id == stylist_id)
        .options(joinedload(Review.replies))
        .all()
    )
    return rows


# ✅ 4. User cập nhật review
@router.put("/{review_id}", response_model=ReviewOut)
def update_review(review_id: int, payload: ReviewUpdate, db: Session = Depends(get_db)):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(404, "Review not found")

    for key, value in payload.dict(exclude_unset=True).items():
        setattr(review, key, value)

    db.commit()
    db.refresh(review)
    return review


# ✅ 5. Admin phản hồi review
@router.post("/reply", response_model=ReviewReplyOut, dependencies=[Depends(admin_required)])
def create_reply(payload: ReviewReplyCreate, db: Session = Depends(get_db)):
    review = db.query(Review).filter(Review.id == payload.review_id).first()
    if not review:
        raise HTTPException(404, "Review not found")

    reply = ReviewReply(**payload.dict())
    db.add(reply)
    db.commit()
    db.refresh(reply)
    return reply


# ✅ 6. Xóa review (Admin)
@router.delete("/{review_id}", dependencies=[Depends(admin_required)])
def delete_review(review_id: int, db: Session = Depends(get_db)):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(404, "Review not found")

    db.delete(review)
    db.commit()
    return {"message": "Deleted successfully"}


# ✅ 7. Xóa phản hồi (Admin)
@router.delete("/reply/{reply_id}", dependencies=[Depends(admin_required)])
def delete_reply(reply_id: int, db: Session = Depends(get_db)):
    reply = db.query(ReviewReply).filter(ReviewReply.id == reply_id).first()
    if not reply:
        raise HTTPException(404, "Reply not found")

    db.delete(reply)
    db.commit()
    return {"message": "Reply deleted"}

# 8️⃣ User tự xoá review của mình
@router.delete("/me/{review_id}")
def delete_my_review(
    review_id: int,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user)
):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    if review.user_id != me.id:
        raise HTTPException(status_code=403, detail="You can only delete your own reviews")

    db.delete(review)
    db.commit()
    return {"message": "Review deleted successfully"}
#Update review.py
# 9️⃣ User lấy danh sách review của chính mình
@router.get("/me", response_model=list[ReviewOut])
def get_my_reviews(
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user)
):
    return (
        db.query(Review)
        .filter(Review.user_id == me.id)
        .order_by(Review.id.desc())
        .all()
    )


# 🔟 User xem review chi tiết của mình
@router.get("/me/{review_id}", response_model=ReviewOut)
def get_my_review_detail(
    review_id: int,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user)
):
    review = (
        db.query(Review)
        .filter(Review.id == review_id, Review.user_id == me.id)
        .first()
    )
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    return review


# 1️⃣1️⃣ User tự cập nhật review của mình
@router.put("/me/{review_id}", response_model=ReviewOut)
def update_my_review(
    review_id: int,
    payload: ReviewUpdate,
    db: Session = Depends(get_db),
    me: User = Depends(get_current_user)
):
    review = (
        db.query(Review)
        .filter(Review.id == review_id, Review.user_id == me.id)
        .first()
    )
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")

    for key, value in payload.dict(exclude_unset=True).items():
        setattr(review, key, value)

    db.commit()
    db.refresh(review)
    return review
