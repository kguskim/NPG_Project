from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.database import SessionLocal
from app.models.ingredient import Ingredient
from app.models.recipe import Recipe
from app.schemas.recipe import RecipeTop3Response
from app.schemas.recipe import RecipeDetailResponse

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 재료에서 핵심만 추출 (예: "달걀 2개" → "달걀")
def extract_main_ingredient(raw_ingredient: str) -> str:
    return raw_ingredient.split()[0].replace("(", "").replace(")", "").strip()

@router.get("/recipes/recommend/advanced/top3", response_model=list[RecipeTop3Response])
def recommend_top3(user_id: str = Query(...), db: Session = Depends(get_db)):
    user_ingredients = db.query(Ingredient.ingredient_name).filter(
        Ingredient.user_id == user_id
    ).all()
    user_ingredients = [i[0] for i in user_ingredients]

    if not user_ingredients:
        return []

    recipes = db.query(Recipe).all()
    results = []

    for recipe in recipes:
        raw_ingredients = [i.strip() for i in recipe.ingredients.split(",")]
        recipe_ings = [extract_main_ingredient(i) for i in raw_ingredients]

        matched = list(set(recipe_ings) & set(user_ingredients))

        if matched:
            results.append({
                "recipe_id": recipe.recipe_id,
                "recipe_name": recipe.recipe_name,
                "match_count": len(matched),
                "image_large": recipe.image_large
            })

    results.sort(key=lambda x: x["match_count"], reverse=True)
    return results[:3]  # 상위 3개만 반환

@router.get("/recipes/{recipe_id}", response_model=RecipeDetailResponse) #상세조회
def get_recipe_detail(recipe_id: int, db: Session = Depends(get_db)):
    recipe = db.query(Recipe).filter(Recipe.recipe_id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")
    return recipe