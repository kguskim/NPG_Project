from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.database import SessionLocal
from app.models.ingredient import Ingredient
from datetime import date
from typing import List
from app.models.recipe import Recipe
from app.schemas.recipe import RecipeTop3Response
from app.schemas.recipe import RecipeDetailResponse
from app.schemas.recipe import RecipeSearchResponse
from app.schemas.recipe import RecipeCreateRequest
import re
import random


router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def extract_main_ingredient(raw_ingredient: str) -> str:
    return raw_ingredient.split()[0].replace("(", "").replace(")", "").strip()

# 재료에서 핵심만 추출 (예: "달걀 2개" → "달걀")
def extract_main_ingredient(raw_ingredient: str) -> str:
    return raw_ingredient.split()[0].replace("(", "").replace(")", "").strip()


def split_steps(text: str) -> list[str]:
    raw = re.split(r"\d+\.\s*", text)
    return [s.strip() for s in raw if s.strip()]



@router.get("/recipes/recommend/advanced/top3", response_model=List[RecipeTop3Response])
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
            # 단계별 이미지 리스트
            step_images = []
            for i in range(1, 7):
                img = getattr(recipe, f"step_img_0{i}")
                if img:
                    step_images.append(img)

            # 단계별 설명 리스트
            step_details = split_steps(recipe.steps_text)

            results.append({
                "id": str(recipe.recipe_id),
                "imageUrl": recipe.image_large or "",
                "title": recipe.recipe_name,
                "ingredients": recipe.ingredients,
                "stepImages": step_images,
                "stepDetails": step_details
            })

    results.sort(key=lambda x: len(x["stepDetails"]), reverse=True)  # 혹은 match 기준
    return results[:3]

@router.get("/recipes/search", response_model=List[RecipeSearchResponse])  # 키워드 레시피 검색
def search_recipes(keyword: str = Query(..., description="검색어"), db: Session = Depends(get_db)):
    recipes = db.query(Recipe).filter(Recipe.recipe_name.like(f"%{keyword}%")).all()

    result = []
    for r in recipes:
        # 단계별 이미지 리스트 추출
        step_images = [getattr(r, f"step_img_0{i}") for i in range(1, 7) if getattr(r, f"step_img_0{i}")]

        # 단계별 설명 리스트 추출 - 수정됨
        step_details = split_steps(r.steps_text) if r.steps_text else []

        result.append({
            "id": str(r.recipe_id),
            "title": r.recipe_name,
            "ingredients": r.ingredients,
            "imageUrl": r.image_large,
            "stepImages": step_images,
            "stepDetails": step_details
        })

    return result

@router.get("/recipes/all", response_model=List[RecipeSearchResponse]) #모든 레시피
def get_all_recipes(db: Session = Depends(get_db)):
    recipes = db.query(Recipe).all()
    result = []

    for r in recipes:
        step_images = [getattr(r, f"step_img_0{i}") for i in range(1, 7) if getattr(r, f"step_img_0{i}")]
        step_details = r.steps_text.split(" ") if r.steps_text else []

        result.append({
            "id": str(r.recipe_id),
            "title": r.recipe_name,
            "ingredients": r.ingredients,
            "imageUrl": r.image_large,
            "stepImages": step_images,
            "stepDetails": step_details
        })

    return result


@router.get("/recipes/{recipe_id}", response_model=RecipeDetailResponse) #상세조회
def get_recipe_detail(recipe_id: int, db: Session = Depends(get_db)):
    recipe = db.query(Recipe).filter(Recipe.recipe_id == recipe_id).first()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")
    return recipe

@router.get("/recipes/recommend/today", response_model=RecipeTop3Response)
def recommend_today(db: Session = Depends(get_db)):
    recipes = db.query(Recipe).all()

    if not recipes:
        raise HTTPException(status_code=404, detail="레시피가 없습니다.")

    recipe = random.choice(recipes)

    # 단계별 이미지 리스트 추출
    step_images = []
    for i in range(1, 7):
        img = getattr(recipe, f"step_img_0{i}")
        if img:
            step_images.append(img)

    # 단계별 설명 리스트 추출
    step_details = split_steps(recipe.steps_text)

    return {
        "id": str(recipe.recipe_id),
        "imageUrl": recipe.image_large or "",
        "title": recipe.recipe_name,
        "ingredients": recipe.ingredients,
        "stepImages": step_images,
        "stepDetails": step_details
    }

@router.get("/recipes/recommend/expire/top3", response_model=List[RecipeTop3Response]) #레시피 임박 top3
def recommend_expiring_top3(user_id: str = Query(...), db: Session = Depends(get_db)):
    # 1. 사용자의 식재료 유통기한 임박순 3개 추출
    user_ingredients = db.query(Ingredient.ingredient_name).filter(
        Ingredient.user_id == user_id
    ).order_by(Ingredient.expiration_date.asc()).limit(3).all()

    if not user_ingredients:
        raise HTTPException(status_code=404, detail="유통기한 임박 재료가 없습니다.")

    ingredient_names = [i.ingredient_name for i in user_ingredients]

    # 2. 레시피 목록에서 이 재료들과 겹치는 레시피 찾기
    recipes = db.query(Recipe).all()
    results = []

    for recipe in recipes:
        raw_ingredients = [i.strip() for i in recipe.ingredients.split(",")]
        recipe_ings = [extract_main_ingredient(i) for i in raw_ingredients]

        matched = list(set(recipe_ings) & set(ingredient_names))
        if matched:
            step_images = [
                getattr(recipe, f"step_img_0{i}") for i in range(1, 7)
                if getattr(recipe, f"step_img_0{i}")
            ]
            step_details = split_steps(recipe.steps_text)

            results.append({
                "id": str(recipe.recipe_id),
                "imageUrl": recipe.image_large or "",
                "title": recipe.recipe_name,
                "ingredients": recipe.ingredients,
                "stepImages": step_images,
                "stepDetails": step_details
            })

    if not results:
        raise HTTPException(status_code=404, detail="추천할 레시피가 없습니다.")

    return results[:3]

@router.get("/recipes/recommend/priority/top3", response_model=List[RecipeTop3Response])
def recommend_priority_top3(user_id: str = Query(...), db: Session = Depends(get_db)):
    today = date.today()

    # 사용자 재료 가져오기
    ingredients = db.query(Ingredient).filter(Ingredient.user_id == user_id).all()
    if not ingredients:
        raise HTTPException(status_code=404, detail="사용자 재료가 없습니다.")

    # 재료명과 유통기한 매핑
    ingredient_map = {
        i.ingredient_name: (i.expiration_date - today).days
        for i in ingredients
    }

    recipes = db.query(Recipe).all()
    ranked_results = []

    for recipe in recipes:
        raw_ingredients = [i.strip() for i in recipe.ingredients.split(",")]
        recipe_ings = [extract_main_ingredient(i) for i in raw_ingredients]
        matched = list(set(recipe_ings) & set(ingredient_map.keys()))

        if not matched:
            continue

        #  match_count와 min_expire_days 정의
        match_count = len(matched)
        min_expire_days = min([ingredient_map[m] for m in matched])
        score = match_count * 10 + max(0, (7 - min_expire_days))

        step_images = [
            getattr(recipe, f"step_img_0{i}") for i in range(1, 7)
            if getattr(recipe, f"step_img_0{i}")
        ]
        step_details = split_steps(recipe.steps_text)

        ranked_results.append({
            "id": str(recipe.recipe_id),
            "imageUrl": recipe.image_large or "",
            "title": recipe.recipe_name,
            "ingredients": recipe.ingredients,
            "stepImages": step_images,
            "stepDetails": step_details,
            "score": score  # 점수 포함
        })

    if not ranked_results:
        raise HTTPException(status_code=404, detail="추천 가능한 레시피가 없습니다.")

    # 점수 기준 내림차순 정렬
    ranked_results.sort(key=lambda x: x["score"], reverse=True)

    # score 필드 제거하고 반환
    return [{k: v for k, v in r.items() if k != "score"} for r in ranked_results[:3]]

@router.post("/recipes/") #레시피 추가
def create_recipe(recipe_data: RecipeCreateRequest, db: Session = Depends(get_db)):
    new_recipe = Recipe(
        serial_number=recipe_data.serial_number,
        recipe_name=recipe_data.recipe_name,
        recipe_type=recipe_data.recipe_type,
        hashtag=recipe_data.hashtag,
        ingredients=recipe_data.ingredients,
        cooking_method=recipe_data.cooking_method,
        tip=recipe_data.tip,
        sodium=recipe_data.sodium,
        protein=recipe_data.protein,
        fat=recipe_data.fat,
        carbohydrate=recipe_data.carbohydrate,
        calorie=recipe_data.calorie,
        step_img_01=recipe_data.step_img_01,
        step_img_02=recipe_data.step_img_02,
        step_img_03=recipe_data.step_img_03,
        step_img_04=recipe_data.step_img_04,
        step_img_05=recipe_data.step_img_05,
        step_img_06=recipe_data.step_img_06,
        image_large=recipe_data.image_large,
        image_small=recipe_data.image_small,
        steps_text=recipe_data.steps_text
    )
    db.add(new_recipe)
    db.commit()
    db.refresh(new_recipe)
    return {"message": "레시피가 성공적으로 등록되었습니다.", "recipe_id": new_recipe.recipe_id}