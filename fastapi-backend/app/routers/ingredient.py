from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.schemas.ingredient import IngredientCreate, IngredientResponse
from app.models.ingredient import Ingredient
from datetime import date, timedelta
from fastapi import Path

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/ingredients", response_model=IngredientResponse)#추가
def create_ingredient(data: IngredientCreate, db: Session = Depends(get_db)):
    new_item = Ingredient(**data.dict())
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item

@router.get("/ingredients", response_model=list[IngredientResponse]) #검색
def get_ingredients(
    user_id: str = Query(..., description="사용자 ID"),
    search: str = Query(None, description="재료명 검색"),
    expire_within: int = Query(None, description="며칠 이내 소비기한"),
    db: Session = Depends(get_db)
):
    today = date.today()


    query = db.query(Ingredient).filter(
        Ingredient.user_id == user_id,
        Ingredient.expiration_date >= today  
    )

    if search:
        query = query.filter(Ingredient.ingredient_name.contains(search))

    if expire_within:
        end_date = today + timedelta(days=expire_within)
        query = query.filter(Ingredient.expiration_date <= end_date)

    return query.all()


@router.put("/ingredients/{ingredient_id}", response_model=IngredientResponse)#수정
def update_ingredient(
    ingredient_id: int,
    update_data: IngredientCreate,
    db: Session = Depends(get_db)
):
    ingredient = db.query(Ingredient).filter(Ingredient.ingredient_id == ingredient_id).first()
    if not ingredient:
        raise HTTPException(status_code=404, detail="해당 재료를 찾을 수 없습니다.")

    for field, value in update_data.dict().items():
        setattr(ingredient, field, value)

    db.commit()
    db.refresh(ingredient)
    return ingredient

@router.delete("/ingredients/{ingredient_id}") #삭제
def delete_ingredient(ingredient_id: int, db: Session = Depends(get_db)):
    ingredient = db.query(Ingredient).filter(Ingredient.ingredient_id == ingredient_id).first()
    if not ingredient:
        raise HTTPException(status_code=404, detail="해당 재료를 찾을 수 없습니다.")

    db.delete(ingredient)
    db.commit()
    return {"message": "재료가 삭제되었습니다."}

