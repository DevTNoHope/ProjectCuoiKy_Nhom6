\# 💈 Barber Booking - Backend (FastAPI + MySQL)



\## 🧩 Tổng quan

Dự án \*\*Barber Booking\*\* là hệ thống đặt lịch cắt tóc nam cho ứng dụng Flutter.  

Backend được xây dựng bằng \*\*FastAPI\*\* kết nối \*\*MySQL\*\*, hỗ trợ \*\*JWT Auth\*\*, \*\*Role-based Access (Admin/User)\*\*, và tích hợp \*\*Google Maps + AI (Gemini)\*\* ở các giai đoạn sau.



---



\## ⚙️ 1️⃣ Yêu cầu môi trường



\### ✅ Cài đặt cần thiết

\- \*\*Python\*\* ≥ 3.12 (khuyến nghị, tránh lỗi pydantic với 3.14)

\- \*\*MySQL Server\*\* ≥ 8.0

\- \*\*Visual Studio Code\*\* (hoặc IDE khác)

\- \*\*Git\*\* (để clone dự án)



---



\## 📦 2️⃣ Thiết lập dự án



\### Bước 1: Clone repository

```bash

git clone https://github.com/<tên-nhóm-hoặc-bạn>/barber-booking-be.git

cd barber-booking-be





Coi thử trong folder có file .venv chưa nếu chưa thì tạo bằng cách là trỏ ngay folder làm việc barber-booking-be ở terminal r chạy lệnh python -m venv .venv để tạo môi trường ảo

Sau đó click phiên bản ngôn ngữ ngay góc dưới bên phải để chọn kiểu .venv r chạy lệnh .\.venv\Scripts\Activate.ps1 để kích hoạt môi trường ảo





Sau khi bật môi trường ảo thì chạy lệnh pip install -r requirements.txt để cài thư viện dự án

sau đó tạo file .env cùng cấp main.py với nội dung:

APP_NAME=Barber Booking API

APP_ENV=development



DB_HOST=localhost

DB_PORT=3306

DB_USER=root

DB_PASS=yourpassword

DB_NAME=barber_booking



JWT_SECRET=supersecretkey123

JWT_ALG=HS256

ACCESS_TOKEN_EXPIRE_MINUTES=60



Lưu ý: thay DB_PASS bằng mật khẩu MySQL thật. Hoặc để nguyên nếu ko cài mật khẩu cho MySQL



Khởi tạo cơ sở dữ liệu

Mở MySQL Workbench hoặc CLI và chạy:

CREATE DATABASE barber_booking CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;



Sau đó, để tạo bảng từ model Python:

python

>>> from app.db.session import Base, engine

>>> import app.models

>>> Base.metadata.create_all(bind=engine)

>>> exit()





Cuối cùng chạy sever ở VS Code bằng câu lệnh uvicorn main:app --reload --port 8000



Server sẽ chạy tại:

&nbsp;http://127.0.0.1:8000



Swagger nằm ở:

http://127.0.0.1:8000/docs

