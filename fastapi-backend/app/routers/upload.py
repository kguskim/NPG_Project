# app/routers/upload.py
from fastapi import APIRouter, UploadFile, File
import os
import shutil
from fastapi.responses import JSONResponse

router = APIRouter()

UPLOAD_DIR = "app/static/images"

@router.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    save_dir = "app/static/images"
    os.makedirs(save_dir, exist_ok=True)
    file_path = os.path.join(save_dir, file.filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    image_url = f"/static/images/{file.filename}"
    return JSONResponse(content={"image_url": image_url})
