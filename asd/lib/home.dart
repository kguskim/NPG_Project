// lib/home.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yolo/food_ingredient_detection_page.dart';
import 'package:yolo/notice_page.dart';
import 'recipe.dart';        // RecipePage
import 'manage.dart';       // ManagePage
import 'login_page.dart';   // LoginPage (로그아웃 후 이동할 페이지)
import 'widgets/to_buy_section.dart';  // 방금 구현한 위젯

/// 공지사항 모델
class Post {
  final int id;
  final String title;
  final DateTime date;
  Post({
    required this.id,
    required this.title,
    required this.date,
  });
}

/// 오늘의 메뉴 모델
class Menu {
  final String name;
  final String imageUrl;
  Menu({required this.name, required this.imageUrl});
}

/// 데이터 서비스 (더미)
class DataService {
  static Future<List<Post>> fetchLatestPosts(int count) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(
      count,
          (i) => Post(
        id: count - i,
        title: '공지 ${count - i}',
        date: DateTime.now().subtract(Duration(days: i)),
      ),
    );
  }

  static Future<Menu> getTodayMenu() async {
    final candidates = [
      Menu(name: '토마토 스프 파스타', imageUrl: 'https://via.placeholder.com/100'),
      Menu(name: '크림 리조또',     imageUrl: 'https://via.placeholder.com/100'),
      Menu(name: '카레 라이스',     imageUrl: 'https://via.placeholder.com/100'),
    ];
    await Future.delayed(const Duration(milliseconds: 300));
    return candidates[Random().nextInt(candidates.length)];
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Post>> _postsFuture;
  late Future<Menu>    _menuFuture;

  // 구매 메모 리스트 (로컬에 보관하려면 SharedPreferences 등 추가)
  List<String> _toBuy = [];

  @override
  void initState() {
    super.initState();
    _postsFuture = DataService.fetchLatestPosts(4);
    _menuFuture  = DataService.getTodayMenu();
  }

  void _addItem() async {
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, text), child: const Text('추가')),
          ],
        );
      },
    );
    if (input != null && input.trim().isNotEmpty) {
      setState(() => _toBuy.add(input.trim()));
    }
  }

  void _removeItem(String txt) {
    setState(() => _toBuy.remove(txt));
  }

  @override
  Widget build(BuildContext context) {
    final expiredNotice = '바나나 소비기한 임박 2025-05-21';
    final formattedDate =
    DateFormat('EEEE d MMMM y HH:mm').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 메인 콘텐츠 스크롤 영역 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 상단 알림 + 아이콘 ──
                    Row(
                      children: [
                        Expanded(child: Text(expiredNotice, style: const TextStyle(fontSize: 14))),
                        IconButton(
                          icon: const Icon(Icons.person),
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ── 날짜/시간 ──
                    Center(child: Text(formattedDate, style: const TextStyle(fontSize: 16))),

                    const SizedBox(height: 24),

                    // ── 중앙 버튼 ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavButton(icon: Icons.emoji_food_beverage, label: '재료', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const App()));
                        }),
                        _NavButton(icon: Icons.kitchen, label: '냉장고 관리', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePage()));
                        }),
                        _NavButton(icon: Icons.menu_book, label: '레시피', onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipePage()));
                        }),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── 공지사항 + 오늘의 메뉴 ──
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 공지사항 (불릿 리스트)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('공지사항', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                FutureBuilder<List<Post>>(
                                  future: _postsFuture,
                                  builder: (ctx, snap) {
                                    if (snap.connectionState != ConnectionState.done ||
                                        snap.hasError ||
                                        snap.data!.isEmpty) {
                                      return const Text('공지 로드 실패');
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: snap.data!
                                          .map((p) => Text('• ${p.title}'))
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // 오늘의 메뉴 (영역 고정)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('오늘의 메뉴',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                FutureBuilder<Menu>(
                                  future: _menuFuture,
                                  builder: (ctx, snap) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: (snap.connectionState == ConnectionState.done &&
                                          snap.hasData)
                                          ? Image.network(snap.data!.imageUrl, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image))
                                          : const SizedBox.shrink(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<Menu>(
                                  future: _menuFuture,
                                  builder: (ctx, snap) =>
                                      Text(snap.hasData ? snap.data!.name : ''),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // (다른 콘텐츠가 더 있다면 여기에 추가)
                  ],
                ),
              ),
            ),

            // ── 구매가 필요한 식재료 (하단 고정) ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

/// 네비 버튼
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

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
