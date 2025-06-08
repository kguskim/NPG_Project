from pydantic import BaseModel

class CategoryMatchResponse(BaseModel):
    ingredient_name: str
    category_name: str

    model_config = {
        "from_attributes": True
    }
