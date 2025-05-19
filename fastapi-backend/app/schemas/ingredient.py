from pydantic import BaseModel
from datetime import date
from typing import Optional

class IngredientCreate(BaseModel): #삽입
    user_id: str
    ingredient_name: str
    quantity: Optional[int] = 1
    purchase_date: date
    expiration_date: date
    alias: Optional[str] = None
    area_id: Optional[int] = None
    image: Optional[str] = None
    note: Optional[str] = None

class IngredientResponse(IngredientCreate):
    ingredient_id: int

    model_config = {
        "from_attributes": True
    }