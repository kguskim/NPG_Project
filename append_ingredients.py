import pymysql

# 식재료 등록
# @param 식재료명, 소비기한, 지역_id
def append_ingredients(ingredient_name, area_id, expiration_date):
    conn = pymysql.connect(host='localhost', user='root', password='password', db='developer', charset='utf8')

    cursor = conn.cursor()

    sql = "INSERT INTO user (ingredient_name, department, area_id) VALUES (%s, %d, %s)"

    cursor.execute(sql, (ingredient_name, area_id, expiration_date))

    conn.commit()
    conn.close()