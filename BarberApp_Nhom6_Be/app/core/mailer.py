# app/core/mailer.py
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import formataddr

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SENDER_EMAIL = "ngthaitu12@gmail.com"
SENDER_NAME = "barber_shop"
SENDER_PASSWORD = "dslv wafg ebtd tdau"  # app password của Gmail

def send_booking_email(to_email: str, customer_name: str, booking_info: dict):
    subject = "Xác nhận lịch hẹn tại Barber Booking"
    body = f"""
Xin chào {customer_name},

Cảm ơn bạn đã đặt lịch tại Barber Booking!

📅 Thời gian: {booking_info['start_dt']} - {booking_info['end_dt']}
🏪 Cửa hàng: {booking_info['shop_name']}
💵 Tổng tiền: {booking_info['total_price']} VND

Hẹn gặp bạn tại tiệm nhé!
"""

    msg = MIMEMultipart()
    msg["From"] = formataddr((SENDER_NAME, SENDER_EMAIL))
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.attach(MIMEText(body, "plain", "utf-8"))

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.send_message(msg)
        print(f"✅ Email đã gửi đến {to_email}")
    except Exception as e:
        print(f"❌ Gửi email thất bại: {e}")
