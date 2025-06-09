from fastapi import APIRouter, Query, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.category import Category 

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/category/match")
def get_category_by_ingredient(ingredient_name: str = Query(...), db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.ingredient_name == ingredient_name).first()
    if not category:
        raise HTTPException(status_code=404, detail="해당 식재료의 카테고리를 찾을 수 없습니다.")
    return {"ingredient_name": category.ingredient_name, "category_name": category.category_name}