from sqlalchemy import Column, Integer, String, Text
from app.database import Base

class Recipe(Base):
    __tablename__ = "recipe_list"

    recipe_id = Column(Integer, primary_key=True, autoincrement=True)
    serial_number = Column(Integer)
    recipe_name = Column(String(100), nullable=False)
    recipe_type = Column(String(50))
    hashtag = Column(String(255))
    ingredients = Column(Text)
    cooking_method = Column(String(50))
    tip = Column(Text)
    sodium = Column(Integer)
    protein = Column(Integer)
    fat = Column(Integer)
    carbohydrate = Column(Integer)
    calorie = Column(Integer)
    step_img_01 = Column(String(255))
    step_img_02 = Column(String(255))
    step_img_03 = Column(String(255))
    step_img_04 = Column(String(255))
    step_img_05 = Column(String(255))
    step_img_06 = Column(String(255))
    image_large = Column(String(255)) 
    image_small = Column(String(255))
    steps_text = Column(Text)
