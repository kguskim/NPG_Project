from models import REcipeList

# models.py에 
def get_available_recipes(user_ingredients):
  """
  사용자가 보유한 식재료(user_ingredients: list)를 입력받아,
  보유한 재료만으로 만들 수 있는 레시피들을 반환하는 함수

  Parameters:
    user_ingredients (list): 사용자가 가진 식재료 목록 (예: ["두부", "김치", "돼지고기"])

  Returns:
    list: 각 레시피의 정보를 담은 딕셔너리 목록
  """
  # 모든 레시피 조회
  recipes = RecipeList.query.all()
  available_recipes = []

  # 각 레시피별 필요한 재료 목록과 사용자의 보유 재료 비교
  for recipe in recipes:
    # recipe.ingredients는 RecipeIngredient와의 관계를 통해 접근
    recipe_ingr = [ri.ingredient_name for ri in recipe.ingredients]

    # 모든 필요한 재료가 사용자의 보유 목록에 있다면 
    if all(ingredient in user_ingredients for ingredient in recipe_ingr):
      available_recipes.append({
        'recipe_id': recipe.recipe_id,
        'recipe_name': recipe.recipe_name,
        'ingredients': recipe_ingr,
        'cook_time_min': recipe.cook_time_min,
        'cook_level': recipe.cook_level
        'recipe_type_id': recipe.type_id,
        'description': recipe_description,
        'image': recipe_image
      })

    return available_recipes
  
# 단위 테스트 또는 모듈 자체 실행용 예제 코드
if __name__ == '__main__':
    # 예시: 사용자가 가진 재료 목록
    sample_ingredients = ["두부", "김치", "돼지고기", "양파"]
    recipes = get_available_recipes(sample_ingredients)
    print("보유 식재료로 가능한 레시피:")
    for r in recipes:
        print(r)