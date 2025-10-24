from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.deps import get_db
from app.core.auth_deps import admin_required
from app.models.service import Service
from app.schemas.service import ServiceOut, ServiceCreate, ServiceUpdate

router = APIRouter(prefix="/services", tags=["services"])


# ✅ 1. Lấy danh sách dịch vụ (public)
@router.get("", response_model=list[ServiceOut])
def list_services(db: Session = Depends(get_db)):
    return db.query(Service).order_by(Service.id.desc()).all()


# ✅ 2. Lấy chi tiết 1 dịch vụ (public)
@router.get("/{service_id}", response_model=ServiceOut)
def get_service(service_id: int, db: Session = Depends(get_db)):
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    return service


# ✅ 3. Tạo mới dịch vụ (Admin)
@router.post(
    "",
    response_model=ServiceOut,
    dependencies=[Depends(admin_required)],
    status_code=status.HTTP_201_CREATED,
)
def create_service(payload: ServiceCreate, db: Session = Depends(get_db)):
    service = Service(**payload.dict())
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


# ✅ 4. Cập nhật dịch vụ (Admin)
@router.put(
    "/{service_id}",
    response_model=ServiceOut,
    dependencies=[Depends(admin_required)],
)
def update_service(service_id: int, payload: ServiceUpdate, db: Session = Depends(get_db)):
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    for key, value in payload.dict(exclude_unset=True).items():
        setattr(service, key, value)

    db.commit()
    db.refresh(service)
    return service


# ✅ 5. Xóa dịch vụ (Admin)
@router.delete(
    "/{service_id}",
    dependencies=[Depends(admin_required)],
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_service(service_id: int, db: Session = Depends(get_db)):
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    db.delete(service)
    db.commit()
    return {"message": "Deleted successfully"}
