# app/schemas/auth.py
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional

class RegisterIn(BaseModel):
    full_name: str
    password: str
    phone: Optional[str] = None
    email: Optional[EmailStr] = None

    @field_validator("phone", "email")
    @classmethod
    def at_least_one(cls, v, info):
        # validator này chỉ chạy từng field; kiểm tra tổng thể ở route
        return v

class LoginIn(BaseModel):
    username: str  # có thể là phone hoặc email
    password: str

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserOut(BaseModel):
    id: int
    full_name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    role: str

    class Config:
        from_attributes = True

from pydantic import BaseModel
from typing import Literal, Optional

class OneSignalRegisterIn(BaseModel):
    player_id: str
    platform: Optional[Literal["android", "ios", "web"]] = "android"