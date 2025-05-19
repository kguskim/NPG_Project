from pydantic import BaseModel
from typing import Optional, List

class RecipeTop3Response(BaseModel):
    recipe_id: int
    recipe_name: str
    match_count: int
    image_large: Optional[str]
    model_config = {
        "from_attributes": True
    }

class RecipeDetailResponse(BaseModel):
    recipe_id: int
    serial_number: Optional[int]
    recipe_name: str
    recipe_type: Optional[str]
    hashtag: Optional[str]
    ingredients: str
    cooking_method: Optional[str]
    tip: Optional[str]
    sodium: Optional[int]
    protein: Optional[int]
    fat: Optional[int]
    carbohydrate: Optional[int]
    calorie: Optional[int]
    step_img_01: Optional[str]
    step_img_02: Optional[str]
    step_img_03: Optional[str]
    step_img_04: Optional[str]
    step_img_05: Optional[str]
    step_img_06: Optional[str]
    image_large: Optional[str]
    image_small: Optional[str]
    steps_text: Optional[str]

    model_config = {
        "from_attributes": True
    }
