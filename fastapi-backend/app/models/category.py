from sqlalchemy import Column, String
from app.database import Base

class Category(Base):
    __tablename__ = "category_list"

    ingredient_name = Column(String(100), primary_key=True)
    category_name = Column(String(100), nullable=False)