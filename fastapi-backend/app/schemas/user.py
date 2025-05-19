from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    user_id: str
    user_email: str
    password: str
    phone: str
    name: str

class UserResponse(BaseModel):
    user_id: str
    user_email: str
    phone: str
    name: str

    model_config = {
        "from_attributes": True
    }


class UserLogin(BaseModel):
    user_id: str
    password: str
