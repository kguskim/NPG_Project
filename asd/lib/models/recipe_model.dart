/// 레시피 데이터 모델
/// 서버 응답(JSON)과 Dart 객체 간 변환을 담당
class RecipeModel {
  /// 레시피 고유 ID
  final String id;

  /// 대표 이미지 URL
  final String imageUrl;

  /// 레시피 제목
  final String title;

  /// 재료 목록
  final String ingredients;

  /// 단계별 이미지 URL 리스트
  final List<String> stepImages;

  /// 단계별 설명 리스트
  final List<String> stepDetails;

  RecipeModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.ingredients,
    required this.stepImages,
    required this.stepDetails,
  });

  /// JSON 맵을 RecipeModel 객체로 변환
  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'],
      imageUrl: json['imageUrl'],
      title: json['title'],
      ingredients: json['ingredients'],
      stepImages:   List<String>.from(json['stepImages']),
      stepDetails:  List<String>.from(json['stepDetails']),
    );
  }
}