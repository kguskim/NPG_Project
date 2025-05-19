from fastapi import FastAPI
from pydantic import BaseModel
from app.routers import ingredient, recipe, user, notice



app = FastAPI()

app.include_router(ingredient.router)
app.include_router(recipe.router)
app.include_router(user.router)
app.include_router(notice.router)
