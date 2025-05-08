// lib/recipe.dart

import 'package:flutter/material.dart';

/// 레시피 페이지: 서버 연결이 안 되어도 기본 UI를 유지하도록 테스트 더미 데이터 사용
class RecipePage extends StatefulWidget {
  final String imageUrl;
  final String title;
  final List<String> ingredients;

  const RecipePage({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.ingredients,
  }) : super(key: key);

  /// 테스트용 더미 데이터 생성자
  factory RecipePage.test() {
    return const RecipePage(
      imageUrl: 'https://via.placeholder.com/400x200.png?text=Recipe+Image',
      title: '토마토 스프 파스타',
      ingredients: [
        '홀토마토 200g',
        '토마토 100g',
        '다진 양파 30g',
        '다진 마늘 20g',
        '먹물 파스타 25g',
        '치즈 25g',
        '올리브 오일 1큰술',
        '소금·후추 약간',
      ],
    );
  }

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  // 요리 종류 드롭다운 옵션
  final List<String> _cuisines = ['양식', '일식', '한식', '중식'];
  String _selectedCuisine = '양식';

  // 검색창 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 바: 뒤로가기 버튼 + 페이지 제목
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      '레시피 추천',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7FA9FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // 뒤로가기 버튼 너비만큼 공간 확보
                ],
              ),
              const SizedBox(height: 8),

              // 필터 영역: 드롭다운 + 검색박스
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedCuisine,
                    items: _cuisines
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCuisine = v);
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '검색',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 이미지 캐러셀 (양쪽 화살표 포함)
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    // 중앙 이미지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 왼쪽 화살표
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 32),
                        onPressed: () {},
                      ),
                    ),
                    // 오른쪽 화살표
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right, size: 32),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 레시피 제목
              Center(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 재료 헤더
              const Text(
                '재료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // 재료 목록 박스
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      itemCount: widget.ingredients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) => Text(
                        '• ${widget.ingredients[index]}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
