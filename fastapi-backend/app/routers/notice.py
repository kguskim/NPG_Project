from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.database import SessionLocal
from app.models.notice import Notice
from app.schemas.notice import NoticeCreate, NoticeUpdate, NoticeResponse

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/notices", response_model=NoticeResponse)
def create_notice(data: NoticeCreate, db: Session = Depends(get_db)):
    notice = Notice(**data.dict())
    db.add(notice)
    db.commit()
    db.refresh(notice)
    return notice

@router.get("/notices", response_model=List[NoticeResponse])
def get_all_notices(db: Session = Depends(get_db)):
    return db.query(Notice).order_by(Notice.created_at.desc()).all()

@router.get("/notices/{notice_id}", response_model=NoticeResponse)
def get_notice_detail(notice_id: int, db: Session = Depends(get_db)):
    notice = db.query(Notice).filter(Notice.notice_id == notice_id).first()
    if not notice:
        raise HTTPException(status_code=404, detail="해당 공지사항이 없습니다.")
    return notice

@router.put("/notices/{notice_id}", response_model=NoticeResponse)
def update_notice(notice_id: int, data: NoticeUpdate, db: Session = Depends(get_db)):
    notice = db.query(Notice).filter(Notice.notice_id == notice_id).first()
    if not notice:
        raise HTTPException(status_code=404, detail="해당 공지사항이 없습니다.")
    
    for field, value in data.dict(exclude_unset=True).items():
        setattr(notice, field, value)
    
    db.commit()
    db.refresh(notice)
    return notice

@router.delete("/notices/{notice_id}")
def delete_notice(notice_id: int, db: Session = Depends(get_db)):
    notice = db.query(Notice).filter(Notice.notice_id == notice_id).first()
    if not notice:
        raise HTTPException(status_code=404, detail="해당 공지사항이 없습니다.")
    
    db.delete(notice)
    db.commit()
    return {"message": "공지사항이 삭제되었습니다."}
