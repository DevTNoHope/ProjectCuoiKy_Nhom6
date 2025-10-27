from pydantic import BaseModel
from typing import Optional

class UserOut(BaseModel):
    id: int
    full_name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    role: Optional[str] = None
    avatar_url: Optional[str] = None

    class Config:
        orm_mode = True
