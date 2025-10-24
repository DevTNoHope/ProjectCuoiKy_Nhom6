# app/api/routers/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.deps import get_db
from app.core.security import get_password_hash, verify_password, create_access_token
from app.schemas.auth import RegisterIn, LoginIn, TokenOut, UserOut
from app.models.user import User, UserRole
from typing import Optional
from app.core.auth_deps import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=UserOut)
def register(payload: RegisterIn, db: Session = Depends(get_db)):
    # bắt buộc có ít nhất email hoặc phone
    if not payload.email and not payload.phone:
        raise HTTPException(status_code=400, detail="Email hoặc phone là bắt buộc.")

    # check trùng
    if payload.email:
        if db.query(User).filter(User.email == payload.email).first():
            raise HTTPException(status_code=400, detail="Email đã tồn tại.")
    if payload.phone:
        if db.query(User).filter(User.phone == payload.phone).first():
            raise HTTPException(status_code=400, detail="Phone đã tồn tại.")

    user = User(
        full_name=payload.full_name,
        email=payload.email,
        phone=payload.phone,
        password_hash=get_password_hash(payload.password),
        role=UserRole.User,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/login", response_model=TokenOut)
def login(payload: LoginIn, db: Session = Depends(get_db)):
    # username có thể là email hoặc phone
    q = db.query(User).filter((User.email == payload.username) | (User.phone == payload.username))
    user: Optional[User] = q.first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Sai thông tin đăng nhập")

    # subject tối thiểu: sub (user_id), role
    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return TokenOut(access_token=token)

@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)):
    return current_user
