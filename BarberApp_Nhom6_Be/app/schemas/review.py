from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List


# 🟢 Tạo mới Review
class ReviewCreate(BaseModel):
    booking_id: int
    user_id: int
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


# 🟡 Cập nhật Review (user sửa nội dung)
class ReviewUpdate(BaseModel):
    rating: Optional[int] = Field(None, ge=1, le=5)
    comment: Optional[str] = None


# 🔵 Trả ra client
class ReviewOut(BaseModel):
    id: int
    booking_id: int
    user_id: int
    rating: int
    comment: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


# 🟢 Tạo phản hồi (Admin)
class ReviewReplyCreate(BaseModel):
    review_id: int
    admin_id: int
    reply: str


# 🔵 Trả ra client
class ReviewReplyOut(BaseModel):
    id: int
    review_id: int
    admin_id: int
    reply: str
    created_at: datetime

    class Config:
        from_attributes = True


# 🔵 Review kèm reply
class ReviewWithReplies(ReviewOut):
    replies: List[ReviewReplyOut] = []
