from fastapi import FastAPI
from pydantic import BaseModel
from app.routers import ingredient, recipe, user, notice, upload, category
from fastapi.staticfiles import StaticFiles




app = FastAPI()

app.include_router(ingredient.router)
app.include_router(recipe.router)
app.include_router(user.router)
app.include_router(notice.router)
app.include_router(upload.router)
app.include_router(category.router)
app.mount("/static", StaticFiles(directory="app/static"), name="static")

