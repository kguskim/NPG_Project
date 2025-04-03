

# 함수 선언
def expiring_soon_filter():
    query = 'SELECT ingredient_name FROM INGREDIENT_LIST WHERE expiration_date BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)'

def expired_filter():
    query = 'SELECT ingredient_name FROM INGREDIENT_LIST WHERE expiration_date < NOW()'