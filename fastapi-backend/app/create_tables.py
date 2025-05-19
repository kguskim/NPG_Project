# app/create_tables.py
from app.database import engine
from app.models.user import Base
from app.models.ingredient import Ingredient

Base.metadata.create_all(bind=engine)
