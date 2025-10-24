from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.deps import get_db
from app.core.auth_deps import admin_required
from app.models.stylist import Stylist, StylistService
from app.models.service import Service
from app.schemas.stylist import StylistOut, StylistCreate, StylistUpdate

router = APIRouter(prefix="/stylists", tags=["stylists"])

# ✅ 1. Lấy danh sách stylist
@router.get("", response_model=list[StylistOut])
def list_stylists(db: Session = Depends(get_db)):
    return db.query(Stylist).order_by(Stylist.id.desc()).all()


# ✅ 2. Lấy stylist theo chi nhánh (shop)
@router.get("/shop/{shop_id}", response_model=list[StylistOut])
def list_by_shop(shop_id: int, db: Session = Depends(get_db)):
    return db.query(Stylist).filter(Stylist.shop_id == shop_id).all()


# ✅ 3. Xem chi tiết 1 stylist
@router.get("/{stylist_id}", response_model=StylistOut)
def get_stylist(stylist_id: int, db: Session = Depends(get_db)):
    stylist = db.query(Stylist).filter(Stylist.id == stylist_id).first()
    if not stylist:
        raise HTTPException(404, "Stylist not found")
    return stylist


# ✅ 4. Tạo mới stylist (Admin)
@router.post(
    "",
    response_model=StylistOut,
    dependencies=[Depends(admin_required)],
    status_code=status.HTTP_201_CREATED,
)
def create_stylist(payload: StylistCreate, db: Session = Depends(get_db)):
    stylist = Stylist(
        shop_id=payload.shop_id,
        name=payload.name,
        bio=payload.bio,
        avatar_url=payload.avatar_url,
        is_active=payload.is_active,
    )
    db.add(stylist)
    db.commit()
    db.refresh(stylist)

    # Gán dịch vụ nếu có
    if payload.service_ids:
        for sid in payload.service_ids:
            db.add(StylistService(stylist_id=stylist.id, service_id=sid))
        db.commit()
    return stylist


# ✅ 5. Cập nhật stylist (Admin)
@router.put(
    "/{stylist_id}",
    response_model=StylistOut,
    dependencies=[Depends(admin_required)],
)
def update_stylist(stylist_id: int, payload: StylistUpdate, db: Session = Depends(get_db)):
    stylist = db.query(Stylist).filter(Stylist.id == stylist_id).first()
    if not stylist:
        raise HTTPException(404, "Stylist not found")

    for key, value in payload.dict(exclude_unset=True, exclude={"service_ids"}).items():
        setattr(stylist, key, value)

    db.commit()
    db.refresh(stylist)

    # Cập nhật dịch vụ stylist
    if payload.service_ids is not None:
        # Xóa dịch vụ cũ
        db.query(StylistService).filter(StylistService.stylist_id == stylist_id).delete()
        db.commit()
        # Thêm dịch vụ mới
        for sid in payload.service_ids:
            db.add(StylistService(stylist_id=stylist_id, service_id=sid))
        db.commit()
    return stylist


# ✅ 6. Xóa stylist (Admin)
@router.delete(
    "/{stylist_id}",
    dependencies=[Depends(admin_required)],
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_stylist(stylist_id: int, db: Session = Depends(get_db)):
    stylist = db.query(Stylist).filter(Stylist.id == stylist_id).first()
    if not stylist:
        raise HTTPException(404, "Stylist not found")
    db.delete(stylist)
    db.commit()
    return {"message": "Deleted successfully"}
