from datetime import datetime, timedelta, timezone
from typing import Any
import jwt
from passlib.context import CryptContext
from app.core.config import settings

# Dùng bcrypt_sha256 để tránh giới hạn 72 byte
pwd_context = CryptContext(schemes=["bcrypt_sha256"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, password_hash: str) -> bool:
    return pwd_context.verify(plain_password, password_hash)

def create_access_token(subject: dict[str, Any], expires_minutes: int | None = None) -> str:
    if expires_minutes is None:
        expires_minutes = int(getattr(settings, "ACCESS_TOKEN_EXPIRE_MINUTES", 60))
    now = datetime.now(tz=timezone.utc)
    exp = now + timedelta(minutes=expires_minutes)
    payload = {"exp": exp, "iat": now, **subject}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALG)

def decode_token(token: str) -> dict[str, Any]:
    return jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALG])
