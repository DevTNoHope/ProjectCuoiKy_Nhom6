from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.deps import get_db
from app.core.auth_deps import admin_required
from app.models.schedule import WorkSchedule
from app.schemas.work_schedule import WorkScheduleOut, WorkScheduleCreate, WorkScheduleUpdate

router = APIRouter(prefix="/work-schedules", tags=["work schedules"])

# ✅ 1. Lấy danh sách ca làm (Admin có thể xem tất cả)
@router.get("", response_model=list[WorkScheduleOut])
def list_work_schedules(db: Session = Depends(get_db)):
    return db.query(WorkSchedule).order_by(WorkSchedule.id.desc()).all()


# ✅ 2. Lấy danh sách ca làm của 1 stylist cụ thể
@router.get("/stylist/{stylist_id}", response_model=list[WorkScheduleOut])
def get_by_stylist(stylist_id: int, db: Session = Depends(get_db)):
    rows = db.query(WorkSchedule).filter(WorkSchedule.stylist_id == stylist_id).all()
    if not rows:
        raise HTTPException(status_code=404, detail="No schedules found for this stylist")
    return rows


# ✅ 3. Tạo mới ca làm (Admin)
@router.post(
    "",
    response_model=WorkScheduleOut,
    dependencies=[Depends(admin_required)],
    status_code=status.HTTP_201_CREATED,
)
def create_work_schedule(payload: WorkScheduleCreate, db: Session = Depends(get_db)):
    schedule = WorkSchedule(**payload.dict())
    db.add(schedule)
    db.commit()
    db.refresh(schedule)
    return schedule


# ✅ 4. Cập nhật ca làm (Admin)
@router.put(
    "/{schedule_id}",
    response_model=WorkScheduleOut,
    dependencies=[Depends(admin_required)],
)
def update_work_schedule(schedule_id: int, payload: WorkScheduleUpdate, db: Session = Depends(get_db)):
    schedule = db.query(WorkSchedule).filter(WorkSchedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Work schedule not found")

    for key, value in payload.dict(exclude_unset=True).items():
        setattr(schedule, key, value)

    db.commit()
    db.refresh(schedule)
    return schedule


# ✅ 5. Xóa ca làm (Admin)
@router.delete(
    "/{schedule_id}",
    dependencies=[Depends(admin_required)],
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_work_schedule(schedule_id: int, db: Session = Depends(get_db)):
    schedule = db.query(WorkSchedule).filter(WorkSchedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Work schedule not found")

    db.delete(schedule)
    db.commit()
    return {"message": "Deleted successfully"}
