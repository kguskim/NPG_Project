from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse, UserLogin
from fastapi.responses import PlainTextResponse


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/users/register", response_model=UserResponse) #회원가입입
def register_user(data: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.user_email == data.user_email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="이미 존재하는 이메일입니다.")
    
    new_user = User(**data.dict())
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.post("/users/login", response_class=PlainTextResponse)
def login_user(data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == data.user_id).first()

    if not user or user.password != data.password:
        raise HTTPException(status_code=400, detail="아이디 또는 비밀번호가 틀렸습니다.")

    return "success"  # 문자열 그대로 반환


@router.post("/users/logout") #로그아웃 이후 JWT 추가 필요
def logout_user():
    return {"message": "로그아웃 되었습니다."}
