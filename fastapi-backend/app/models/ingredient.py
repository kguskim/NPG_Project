from sqlalchemy import Column, Integer, String, Date, Text
from app.database import Base

class Ingredient(Base):
    __tablename__ = "ingredient_list"

    ingredient_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(String(50), nullable=False)
    ingredient_name = Column(String(100), nullable=False)
    quantity = Column(Integer, default=1)
    purchase_date = Column(Date, nullable=False)
    expiration_date = Column(Date, nullable=False)
    alias = Column(String(100), nullable=True)
    area_id = Column(Integer, nullable=True)
    fridge_id = Column(Integer, nullable=True)
    image = Column(String(255), nullable=True)
    note = Column(Text, nullable=True)
