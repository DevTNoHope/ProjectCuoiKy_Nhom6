from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserOut
from app.core.deps import get_db
from app.core.auth_deps import admin_required

router = APIRouter(prefix="/users", tags=["users"])

# 🟢 Admin lấy danh sách tất cả user
@router.get("", response_model=list[UserOut], dependencies=[Depends(admin_required)])
def list_users(db: Session = Depends(get_db)):
    users = db.query(User).filter(User.role == "user").order_by(User.id.desc()).all()
    if not users:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No users found")
    return users
