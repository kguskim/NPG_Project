// lib/recipe.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/recipe_model.dart';
import 'detailed_recipe.dart';

/// 추천 레시피 가져오기 (userId 로 3개)
Future<List<RecipeModel>> fetchUserRecipes(String userId) async {
  final uri = Uri.parse(
    'https://efb4-121-188-29-7.ngrok-free.app/recipes/recommend/advanced/top3'
    '?user_id=${Uri.encodeComponent(userId)}',
  );
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } else {
    throw Exception('레시피를 불러오는 데 실패했습니다.');
  }
}

class RecipePage extends StatefulWidget {
  final String userId;
  const RecipePage({Key? key, required this.userId}) : super(key: key);

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  // 검색창 컨트롤러
  final TextEditingController _searchController = TextEditingController();
  // 검색 결과
  List<RecipeModel> _searchResults = [];

  // 캐러셀 컨트롤러
  late final PageController _pageController;
  int _currentIndex = 0;

  // 추천 레시피 Future
  late final Future<List<RecipeModel>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _recipesFuture = fetchUserRecipes(widget.userId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 키워드 검색 API 호출
  Future<void> searchByKeyword() async {
    // 키보드 내리기
    FocusScope.of(context).unfocus();

    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      // 검색어 비우면 추천 캐러셀로 돌아가기
      setState(() => _searchResults.clear());
      return;
    }

    final uri = Uri.parse(
      'https://efb4-121-188-29-7.ngrok-free.app/recipes/search'
      '?keyword=${Uri.encodeComponent(keyword)}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _searchResults = data
              .map((e) => RecipeModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                const Text(
                  '레시피 추천',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7FA9FF),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
            // ───── 검색창 ─────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => searchByKeyword(),
                decoration: InputDecoration(
                  hintText: '레시피 키워드를 입력하세요',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: searchByKeyword,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
            ),

            // ───── 검색 결과 or 추천 캐러셀 ───────────
            Expanded(
              child: _searchResults.isNotEmpty
                  // 검색 결과가 있으면 리스트로 보여줌
                  ? ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, i) {
                        final r = _searchResults[i];
                        return ListTile(
                          leading: Image.network(
                            r.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                          title: Text(r.title),
                          subtitle: Text(r.ingredients),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailedRecipePage(
                                imageUrls: r.stepImages,
                                steps: r.stepDetails,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  // 검색 결과가 없으면 추천 캐러셀 보여줌
                  : FutureBuilder<List<RecipeModel>>(
                      future: _recipesFuture,
                      builder: (ctx, snap) {
                        if (snap.connectionState != ConnectionState.done ||
                            snap.hasError ||
                            (snap.data?.length ?? 0) < 1) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final recipes = snap.data!;
                        final itemCount = recipes.length + 2;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ─── 상단 바 ────────────────────

                              const SizedBox(height: 8),

                              // ─── 캐러셀 ─────────────────────
                              Expanded(
                                child: Stack(
                                  children: [
                                    PageView.builder(
                                      controller: _pageController,
                                      itemCount: itemCount,
                                      onPageChanged: (page) {
                                        if (page == 0) {
                                          _pageController
                                              .jumpToPage(recipes.length);
                                          page = recipes.length;
                                        } else if (page ==
                                            itemCount - 1) {
                                          _pageController.jumpToPage(1);
                                          page = 1;
                                        }
                                        setState(
                                            () => _currentIndex = page - 1);
                                      },
                                      itemBuilder: (ctx, page) {
                                        final idx = page == 0
                                            ? recipes.length - 1
                                            : page == itemCount - 1
                                                ? 0
                                                : page - 1;
                                        final r = recipes[idx];
                                        return GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DetailedRecipePage(
                                                imageUrls: r.stepImages,
                                                steps: r.stepDetails,
                                              ),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              r.imageUrl,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (_, __, ___) => Container(
                                                color:
                                                    Colors.grey.shade200,
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

                                    // ◀️ 왼쪽 화살표
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.chevron_left,
                                            size: 32),
                                        onPressed: () =>
                                            _pageController.previousPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                    ),

                                    // ▶️ 오른쪽 화살표
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.chevron_right,
                                            size: 32),
                                        onPressed: () =>
                                            _pageController.nextPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ─── 제목 & 재료 ────────────────
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
                              const Text(
                                '재료',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    recipes[_currentIndex].ingredients,
                                    style:
                                        const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
