// 챗봇 식재료 DB 연동 파일

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fuzzy/fuzzy.dart';

class DatabaseHelper {
  // 싱글톤 패턴으로 인스턴스 관리
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  // 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ingredients.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // 테이블 생성 및 샘플 데이터 추가
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ingredients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        area_id TEXT NOT NULL
      )
    ''');
    // 💡 데모를 위한 샘플 데이터입니다. 실제 앱에서는 서버에서 받아오거나 관리자 페이지에서 추가해야 합니다.
    await _seedDatabase(db);
  }

  // 샘플 데이터 추가 함수
  Future<void> _seedDatabase(Database db) async {
    await db.insert('ingredients', {'name': '사과', 'area_id': 'A-1 (과일 코너)'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('ingredients', {'name': '바나나', 'area_id': '냉장실 1층 오른쪽'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('ingredients', {'name': '돼지고기', 'area_id': 'C-4 (정육 코너)'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('ingredients', {'name': '대파', 'area_id': 'B-3 (채소 코너)'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('ingredients', {'name': '양파', 'area_id': 'B-3 (채소 코너)'}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // 식재료 위치를 찾는 메인 함수
  Future<Map<String, dynamic>?> findIngredientLocation(String userInputName) async {
    final db = await instance.database;

    // 1. 먼저 정확히 일치하는 이름이 있는지 확인
    var results = await db.query('ingredients', where: 'name = ?', whereArgs: [userInputName]);
    if (results.isNotEmpty) {
      return results.first;
    }

    // 2. 정확히 일치하는 결과가 없으면, 유사한 식재료 검색 (오타 교정)
    var allIngredients = await db.query('ingredients', columns: ['name']);
    if (allIngredients.isEmpty) return null;

    // DB에 있는 모든 식재료 이름 리스트 생성
    final ingredientNames = allIngredients.map((item) => item['name'] as String).toList();

    // Fuzzy 검색 설정 (threshold로 민감도 조절, 0.5는 중간 정도)
    final fuse = Fuzzy(
      ingredientNames,
      options: FuzzyOptions(threshold: 0.5),
    );

    // 사용자의 입력과 가장 유사한 단어 검색
    final searchResults = fuse.search(userInputName);

    if (searchResults.isNotEmpty) {
      // 가장 유사도가 높은 결과의 이름으로 다시 DB에서 정보 조회
      final bestMatchName = searchResults.first.item;
      var finalResults = await db.query('ingredients', where: 'name = ?', whereArgs: [bestMatchName]);
      if (finalResults.isNotEmpty) {
        return finalResults.first;
      }
    }

    // 어떤 결과도 찾지 못한 경우
    return null;
  }
}