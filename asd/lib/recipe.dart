// lib/recipe.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'models/recipe_model.dart';
import 'services/recipe_extraction.dart';
import 'detailed_recipe.dart';


/// 레시피 추천 페이지 (항상 3개 순환 캐러셀 + 기존 UI 틀 유지)
class RecipePage extends StatefulWidget {
  final String userId;
  const RecipePage({Key? key, required this.userId}) : super(key: key);
  @override
  _RecipePageState createState() => _RecipePageState();
}
// API 요청 함수 수정
Future<List<RecipeModel>> fetchUserRecipes(String userId) async {
  final uri = Uri.parse('https://efb4-121-188-29-7.ngrok-free.app/recipes/recommend/advanced/top3?user_id=$userId');

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => RecipeModel.fromJson(e)).toList();
  } else {
    throw Exception('레시피를 불러오는 데 실패했습니다.');
  }
}


class _RecipePageState extends State<RecipePage> {

  // — 검색창 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  // — PageView 컨트롤러 & 현재 인덱스
  late final PageController _pageController;
  int _currentIndex = 0;

  // — 3개 레시피를 불러올 Future
  late final Future<List<RecipeModel>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    // 초기 페이지를 1로 주어, 0번에는 마지막 아이템을 복제해서 넣습니다.
    _pageController = PageController(initialPage: 1);
    _recipesFuture = fetchUserRecipes(widget.userId); // ← 여기에 userId 전달
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 키보드 올라와도 깨지지 않도록
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FutureBuilder<List<RecipeModel>>(
          future: _recipesFuture,
          builder: (ctx, snap) {
            // 로딩 또는 에러 처리
            if (snap.connectionState != ConnectionState.done ||
                snap.hasError ||
                (snap.data?.length ?? 0) < 1) {
              return const Center(child: CircularProgressIndicator());
            }
            final recipes = snap.data!;      // 길이 == 3 보장
            final itemCount = recipes.length + 2; // 앞뒤 복제 포함

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── 상단 바
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      Text(
                        '레시피 추천',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7FA9FF),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ─── 필터 (드롭다운 + 검색)
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _selectedCuisine,
                        items: _cuisines
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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

                  // ─── 무한 루프 캐러셀 영역 ───
                  Expanded(
                    child: Stack(
                      children: [
                        // PageView: [복제마지막, 0, 1, 2, 복제첫] 총 5페이지
                        PageView.builder(
                          controller: _pageController,
                          itemCount: itemCount,
                          onPageChanged: (page) {
                            // 끝단 보정: 0→마지막 원본, 끝+1→첫 원본
                            if (page == 0) {
                              _pageController.jumpToPage(recipes.length);
                              page = recipes.length;
                            } else if (page == itemCount - 1) {
                              _pageController.jumpToPage(1);
                              page = 1;
                            }
                            // 실제 데이터 인덱스 = page - 1
                            setState(() => _currentIndex = page - 1);
                          },
                          itemBuilder: (ctx, page) {
                            // page → recipes 인덱스 매핑
                            final int idx = (page == 0)
                                ? recipes.length - 1
                                : (page == itemCount - 1)
                                ? 0
                                : page - 1;
                            final r = recipes[idx];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailedRecipePage(
                                      imageUrls: r.stepImages,
                                      steps: r.stepDetails,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  r.imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
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
                            );
                          },
                        ),

                        // ◀️ 왼쪽 화살표 (항상 오른쪽으로 넘어가는 애니메이션만 사용)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, size: 32),
                            onPressed: () {
                              // 오른쪽으로 한 칸씩 이동
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                        // ▶️ 오른쪽 화살표
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, size: 32),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── 레시피 제목
                  Text(
                    recipes[_currentIndex].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),

                  // ─── 재료 헤더
                  const Text(
                    '재료',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // ─── 재료 박스
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        itemCount: recipes[_currentIndex].ingredients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (ctx, i) => Text(
                          '• ${recipes[_currentIndex].ingredients[i]}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
