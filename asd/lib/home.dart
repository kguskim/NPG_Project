// lib/home.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolo/food_ingredient_detection_page.dart';
import 'package:yolo/login_page.dart';
import 'package:yolo/manage.dart';
import 'package:yolo/recipe.dart';
import 'package:yolo/detailed_recipe.dart';
import 'models/recipe_model.dart'; // <-- RecipeModel 을 재사용
import 'widgets/to_buy_section.dart';

/// 공지사항 모델
class Post {
  final int id;
  final String title;
  final DateTime date;

  Post({required this.id, required this.title, required this.date});
}

/// 더미 데이터 서비스 (공지사항)
class DataService {
  static Future<List<Post>> fetchLatestPosts(int count) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(
      count,
          (i) =>
          Post(
            id: count - i,
            title: '공지 ${count - i}',
            date: DateTime.now().subtract(Duration(days: i)),
          ),
    );
  }
}

/// 오늘의 메뉴를 RecipeModel 로 가져오는 함수
Future<RecipeModel> fetchTodayRecipe(String userId) async {
  final list = await fetchUserRecipes(userId); // RecipePage 에서 쓰던 함수
  if (list.isEmpty) throw Exception('오늘의 메뉴가 없습니다');
  return list.first; // 가장 첫 번째 레시피를 오늘의 메뉴로 사용
}

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Post>> _postsFuture;
  late Future<RecipeModel> _todayFuture;
  List<String> _toBuy = [];

  @override
  void initState() {
    super.initState();
    _loadToBuy();
    _postsFuture = DataService.fetchLatestPosts(4);
    _todayFuture = fetchTodayRecipe(widget.userId);
  }

  // SharedPreferences에서 구매할 리스트 불러오기
  Future<void> _loadToBuy() async {
    final prefs = await SharedPreferences.getInstance();
    _toBuy = prefs.getStringList('toBuy') ?? [];
    setState(() {});
  }

  Future<void> _saveToBuy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('toBuy', _toBuy);
  }

  Future<void> _addItem() async {
    final input = await showDialog<String>(
      context: context,
      builder: (_) {
        String text = '';
        return AlertDialog(
          title: const Text('추가할 식재료'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: '예: 토마토 2개'),
            onChanged: (v) => text = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, text),
                child: const Text('추가')),
          ],
        );
      },
    );
    if (input != null && input
        .trim()
        .isNotEmpty) {
      _toBuy.add(input.trim());
      await _saveToBuy();
      setState(() {});
    }
  }

  Future<void> _removeItem(String txt) async {
    _toBuy.remove(txt);
    await _saveToBuy();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final expiredNotice = '소비기한이 3일 남은 식재료';
    final formattedDate = DateFormat('EEEE d MMMM y HH:mm').format(
        DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          Builder(builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.person),
              onPressed: () async {
                final button = ctx.findRenderObject() as RenderBox;
                final overlay = Overlay.of(ctx)!.context
                    .findRenderObject() as RenderBox;
                final pos = button.localToGlobal(
                    Offset.zero, ancestor: overlay);
                final selected = await showMenu<String>(
                  context: ctx,
                  position: RelativeRect.fromLTRB(
                    pos.dx, pos.dy + button.size.height,
                    pos.dx + button.size.width, pos.dy,
                  ),
                  items: [const PopupMenuItem(value: 'logout', child: Text(
                      'LOGOUT'))
                  ],
                );
                if (selected == 'logout') {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                }
              },
            );
          }),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 메인 스크롤 영역 ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 만료 알림
                    Text(expiredNotice, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Center(child: Text(
                        formattedDate, style: const TextStyle(fontSize: 16))),
                    const SizedBox(height: 24),

                    // 네비 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavButton(
                          icon: Icons.emoji_food_beverage,
                          label: '재료',
                          onTap: () =>
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => App(userId: widget.userId)),
                              ),
                        ),
                        _NavButton(
                          icon: Icons.kitchen,
                          label: '냉장고 관리',
                          onTap: () =>
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ManagePage()),
                              ),
                        ),
                        _NavButton(
                          icon: Icons.menu_book,
                          label: '레시피',
                          onTap: () =>
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) =>
                                    RecipePage(userId: widget.userId)),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ─── 오늘의 메뉴 영역 ───
                    const Text('오늘의 메뉴',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    FutureBuilder<RecipeModel>(
                      future: _todayFuture,
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return const Text('오늘의 메뉴 불러오기 실패');
                        }
                        final today = snap.data!;
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetailedRecipePage(
                                          imageUrls: today.stepImages,
                                          steps: today.stepDetails,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.network(
                                  today.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(today.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // ─── 공지사항 영역 ───
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('공지사항',
                                    style: TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                FutureBuilder<List<Post>>(
                                  future: _postsFuture,
                                  builder: (ctx, snap) {
                                    if (snap.connectionState !=
                                        ConnectionState.done ||
                                        snap.hasError ||
                                        snap.data!.isEmpty) {
                                      return const Text('공지 로드 실패');
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: snap.data!
                                          .map((p) =>
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Text(p.title,
                                                style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .none)),
                                          ))
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ─── 구매가 필요한 식재료 ───
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ToBuySection(
                items: _toBuy,
                onAdd: _addItem,
                onRemove: _removeItem,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 네비 버튼 위젯
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton(
      {Key? key, required this.icon, required this.label, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
