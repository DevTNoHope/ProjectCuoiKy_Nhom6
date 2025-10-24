# app/api/routers/shops.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.deps import get_db
from app.core.auth_deps import admin_required
from app.models.shop import Shop
from app.schemas.shop import ShopOut, ShopCreate, ShopUpdate

router = APIRouter(prefix="/shops", tags=["shops"])


# ✅ 1. Lấy danh sách tất cả cửa hàng (public)
@router.get("", response_model=list[ShopOut])
def list_shops(db: Session = Depends(get_db)):
    return db.query(Shop).order_by(Shop.id.desc()).all()


# ✅ 2. Lấy chi tiết một cửa hàng (public)
@router.get("/{shop_id}", response_model=ShopOut)
def get_shop(shop_id: int, db: Session = Depends(get_db)):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    return shop


# ✅ 3. Tạo mới cửa hàng (Admin)
@router.post(
    "",
    response_model=ShopOut,
    dependencies=[Depends(admin_required)],
    status_code=status.HTTP_201_CREATED,
)
def create_shop(payload: ShopCreate, db: Session = Depends(get_db)):
    shop = Shop(**payload.dict())
    db.add(shop)
    db.commit()
    db.refresh(shop)
    return shop


# ✅ 4. Cập nhật thông tin cửa hàng (Admin)
@router.put(
    "/{shop_id}",
    response_model=ShopOut,
    dependencies=[Depends(admin_required)],
)
def update_shop(shop_id: int, payload: ShopUpdate, db: Session = Depends(get_db)):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    # cập nhật các field có giá trị
    for key, value in payload.dict(exclude_unset=True).items():
        setattr(shop, key, value)

    db.commit()
    db.refresh(shop)
    return shop


# ✅ 5. Xóa cửa hàng (Admin)
@router.delete(
    "/{shop_id}",
    dependencies=[Depends(admin_required)],
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_shop(shop_id: int, db: Session = Depends(get_db)):
    shop = db.query(Shop).filter(Shop.id == shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    db.delete(shop)
    db.commit()
    return {"message": "Deleted successfully"}
