from models import RecipeList

def get_optional_recipes(user_ingredients, missing_threshold=1):
    """
    사용자가 보유한 식재료(user_ingredients: list)와 허용 누락 재료 수(missing_threshold)를 입력받아,
    추가 구매가 필요한 레시피들을 반환하는 함수입니다.
    
    Parameters:
        user_ingredients (list): 사용자가 가진 식재료 목록 (예: ["두부", "김치", "돼지고기"])
        missing_threshold (int): 허용하는 누락 재료 수 (예: 1)
        
    Returns:
        list: 각 레시피의 정보를 담은 딕셔너리 목록. 각 딕셔너리에는
              recipe_id, recipe_name, ingredients, missing_ingredients,
              cook_time_min, cook_level, recipe_type_id, description, image(이미지 URL)가 포함됩니다.
    """
    # 데이터베이스에서 모든 레시피 조회
    recipes = RecipeList.query.all()
    optional_recipes = []
    
    for recipe in recipes:
        # 레시피에 필요한 재료 목록 (RecipeIngredient와의 관계를 통해 접근)
        recipe_ingr = [ri.ingredient_name for ri in recipe.ingredients]
        
        # 사용자가 보유한 재료에 없는 재료 리스트
        missing = [ingredient for ingredient in recipe_ingr if ingredient not in user_ingredients]
        
        # 누락된 재료 수가 허용 범위 이내라면 해당 레시피를 결과에 추가
        if len(missing) <= missing_threshold:
            optional_recipes.append({
                'recipe_id': recipe.recipe_id,
                'recipe_name': recipe.recipe_name,
                'ingredients': recipe_ingr,
                'missing_ingredients': missing,
                'cook_time_min': recipe.cook_time_min,
                'cook_level': recipe.cook_level,
                'recipe_type_id': recipe.type_id,
                'description': recipe.description,
                'image': recipe.image_url
            })
    
    return optional_recipes

# 단위 테스트 또는 모듈 자체 실행용 예제 코드
if __name__ == '__main__':
    # 예시: 사용자가 보유한 식재료 목록
    sample_ingredients = ["두부", "김치", "돼지고기", "양파"]
    recipes = get_optional_recipes(sample_ingredients, missing_threshold=1)
    print("보유 식재료에 추가 구매가 필요한 레시피:")
    for r in recipes:
        print(r)
