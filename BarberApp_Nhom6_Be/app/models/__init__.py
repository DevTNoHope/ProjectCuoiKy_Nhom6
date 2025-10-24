# app/models/__init__.py
from .base import Base  # giữ Base trong namespace (tuỳ chọn)

from .user import User, UserRole
from .shop import Shop
from .service import Service
from .stylist import Stylist, StylistService
from .schedule import WorkSchedule
from .booking import Booking, BookingService, BookingStatus
from .review import Review, ReviewReply
from .device import Device
from .chat import ChatMessage
from .image import Image
from .otp import OtpCode
