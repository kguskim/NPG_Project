from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class NoticeCreate(BaseModel):
    title: str
    author: str
    content: str

class NoticeUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None

class NoticeResponse(BaseModel):
    notice_id: int
    title: str
    author: str
    content: str
    created_at: datetime

    model_config = {
        "from_attributes": True
    }
