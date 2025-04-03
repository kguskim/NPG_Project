

# DB 연결 함수
def db_connection():
    return pymysql.connect(
        host = ''
        user = ''
        password = ''

    )

# 필터 함수
def search_filter():
    # 필터링 조건 받음
    difficulty = request.args.getlist('cook_level')
    time_range = request.args.getlist('cook_time')
    category = request.args.getlist('recipe_type_id')

    # 기본 쿼리 틀
    query = 'SELECT * FROM RECIPE_LIST WHERE 1=1'
    filter_params = []

    # 난이도 필터
    if difficulty:
        # ,구분자 / 입력 레벨 수 만큼 %s 추가
        query += "AND cook_level IN(%s)" % ','.join(['%s'] * len(difficulty))
        filter_params.extend(difficulty)
    
    # 시간 필터
    if time_range:
        if time_range == 'under 20':
            query += "AND cook_time < 20"
        elif time_range == '20 to 40':
            query += "AND cook_time BETWEEN 20 AND 40"
        elif time_range == ' 40 to 60':
            query += "AND cook_time BETWEEN 40 AND 60"
        else:
            query += "AND cook_time > 60"

    # 요리 종류 필터
    if category:
        query += "AND recipe_type_id IN(%s)" % ','.join(['%s'] * len(category))
        filter_params.extend(category)
   
    # query, params 로 보냄냄



