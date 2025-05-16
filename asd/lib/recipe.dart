// lib/recipe.dart

import 'package:flutter/material.dart';
import 'models/recipe_model.dart';
import 'services/recipe_extraction.dart';
import 'detailed_recipe.dart';

/// 레시피 추천 페이지 (3개 순환 캐러셀, 항상 오른쪽으로 이동)
class RecipePage extends StatefulWidget {
  const RecipePage({Key? key}) : super(key: key);
  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final List<String> _cuisines = ['양식', '일식', '한식', '중식'];
  String _selectedCuisine = '양식';
  final TextEditingController _searchController = TextEditingController();

  late final PageController _pageController;
  int _currentIndex = 0; // 실제 데이터 인덱스 (0~2)

  // 3개 레시피를 불러옴
  late final Future<List<RecipeModel>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    // 앞뒤에 복제 페이지를 위해 initialPage=1
    _pageController = PageController(initialPage: 1);
    _recipesFuture = RecipeExtraction.fetchRandomRecipes(3);
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FutureBuilder<List<RecipeModel>>(
          future: _recipesFuture,
          builder: (ctx, snap) {
            // 로딩/에러/빈 경우
            if (snap.connectionState != ConnectionState.done ||
                snap.hasError ||
                (snap.data?.length ?? 0) < 1) {
              return const Center(child: CircularProgressIndicator());
            }
            final recipes = snap.data!;  // 길이 3 보장

            // 실제로 페이지에 보여줄 아이템 수 = recipes.length + 2
            // [복제_마지막, 원본0, 원본1, 원본2, 복제_첫번째]
            final itemCount = recipes.length + 2;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // 상단 바 & 필터 생략…
                  // ─── 캐러셀 ───
                  Expanded(
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: itemCount,
                          onPageChanged: (page) {
                            if (page == 0) {
                              // 왼쪽 끝(복제 마지막) → 실제 마지막 페이지(인덱스 recipes.length)
                              _pageController.jumpToPage(recipes.length);
                              page = recipes.length;
                            } else if (page == recipes.length + 1) {
                              // 오른쪽 끝(복제 첫) → 실제 첫 페이지(인덱스 1)
                              _pageController.jumpToPage(1);
                              page = 1;
                            }
                            // 실제 데이터 인덱스는 page-1
                            setState(() {
                              _currentIndex = page - 1;
                            });
                          },
                          itemBuilder: (ctx, page) {
                            // map page → 실제 recipe 인덱스
                            int idx;
                            if (page == 0) {
                              idx = recipes.length - 1;
                            } else if (page == recipes.length + 1) {
                              idx = 0;
                            } else {
                              idx = page - 1;
                            }
                            final r = recipes[idx];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailedRecipePage(
                                    imageUrls: r.stepImages,
                                    steps:     r.stepDetails,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  r.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                        // ◀️
                        Positioned(
                          left: 0, top: 0, bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, size: 32),
                            onPressed: () {
                              _pageController.nextPage( // nextPage 대신 animateToPage(current-1)
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                        // ▶️
                        Positioned(
                          right: 0, top: 0, bottom: 0,
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
                  Text(
                    recipes[_currentIndex].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),

                  Text('재료', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
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
                        itemBuilder: (ctx, i) => Text('• ${recipes[_currentIndex].ingredients[i]}'),
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
