from pydantic import BaseModel
from datetime import date
from typing import Optional

class IngredientCreate(BaseModel): 
    user_id: str
    ingredient_name: str
    quantity: Optional[int] = 1
    purchase_date: date
    expiration_date: date
    alias: Optional[str] = None
    area_id: Optional[int] = None
    image: Optional[str] = None
    note: Optional[str] = None
    fridge_id: Optional[int] = None 

class IngredientResponse(IngredientCreate):
    ingredient_id: int

    model_config = {
        "from_attributes": True
    }

class IngredientSearchResponse(BaseModel): 
    alias: Optional[str]
    ingredient_name: str
    quantity: int
    purchase_date: date
    expiration_date: date
    image: Optional[str]
    note: Optional[str]
    fridge_id: Optional[int]
    area_id: Optional[int]

    class Config:
        orm_mode = True