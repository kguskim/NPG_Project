import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';

/// 레시피 추출 서비스
/// 서버에서 랜덤 n개 레시피를 가져오고, 실패 시 더미 데이터를 반환
class RecipeExtraction {
  /// 서버 API 호출 또는 타임아웃 시 더미 사용
  static Future<List<RecipeModel>> fetchRandomRecipes(int count) async {
    try {
      final uri = Uri.parse('https://example.com/api/recipes?random=$count');
      final res = await http.get(uri).timeout(Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        return data.map((e) => RecipeModel.fromJson(e)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('서버 로드 실패: $e');
    }
    return _getDummyRecipes(count);
  }

  /// 오프라인 대비용 더미 리스트 생성
  static List<RecipeModel> _getDummyRecipes(int count) {
    final all = <RecipeModel>[
      RecipeModel(
        id: 'dummy1',
        imageUrl: 'https://via.placeholder.com/200?text=Dummy+1',
        title: '더미 레시피 1',
        ingredients: '재료 A, 재료 B',
        stepImages: [
          'https://via.placeholder.com/400x200?text=Step+1',
          'https://via.placeholder.com/400x200?text=Step+2',
          'https://via.placeholder.com/400x200?text=Step+3',
        ],
        stepDetails: [
          '1. 재료 A 준비하기',
          '2. 재료 B 볶기',
          '3. 맛있게 서빙',
        ],
      ),

      RecipeModel(
        id: 'dummy2',
        imageUrl: 'https://via.placeholder.com/200?text=Dummy+2',
        title: '더미 레시피 2',
        ingredients: '재료 C, 재료 D',
        stepImages: [
          'https://via.placeholder.com/400x200?text=C-Step+1',
          'https://via.placeholder.com/400x200?text=C-Step+2',
        ],
        stepDetails: [
          '1. 재료 C 다듬기',
          '2. 재료 C와 D 조리하기',
        ],
      ),

      RecipeModel(
        id: 'dummy3',
        imageUrl: 'https://via.placeholder.com/200?text=Dummy+3',
        title: '더미 레시피 3',
        ingredients: '재료 E, 재료 F',
        stepImages: [
          'https://via.placeholder.com/400x200?text=E-Step+1',
        ],
        stepDetails: [
          '1. 재료 E 준비하기',
        ],
      ),

      // 필요하다면 더 추가…
    ];
    all.shuffle(Random());
    return all.take(count).toList();
  }
}