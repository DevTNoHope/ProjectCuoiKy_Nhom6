# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.routers import health, shops
from app.api.routers import auth  # <-- thêm
from app.api.routers import shops, services
from app.api.routers import shops, services, work_schedules
from app.api.routers import shops, services, stylists, work_schedules
from app.api.routers import shops, services, stylists, work_schedules, bookings
from app.api.routers import reviews
app = FastAPI(title=settings.APP_NAME)

# CORS cho Flutter (tuỳ cập nhật origin sau)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(health.router)
app.include_router(auth.router)   # <-- thêm
app.include_router(shops.router)

app.include_router(shops.router)
app.include_router(services.router)
app.include_router(shops.router)
app.include_router(services.router)
app.include_router(work_schedules.router)

app.include_router(shops.router)
app.include_router(services.router)
app.include_router(stylists.router)
app.include_router(work_schedules.router)

app.include_router(shops.router)
app.include_router(services.router)
app.include_router(stylists.router)
app.include_router(work_schedules.router)
app.include_router(bookings.router)

app.include_router(reviews.router)
@app.get("/")
def root():
    return {"app": settings.APP_NAME, "env": settings.APP_ENV}
