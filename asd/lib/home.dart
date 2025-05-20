// lib/home.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:yolo/food_ingredient_detection_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolo/notice_page.dart';
import 'recipe.dart'; // RecipePage
import 'manage.dart'; // ManagePage
import 'login_page.dart'; // LoginPage
import 'widgets/to_buy_section.dart';

/// 만료 알림을 가져오는 API 호출 함수
Future<String> fetchExpireNotice(String userId, int days) async {
  final uri = Uri.parse(
    'https://YOUR_API_ENDPOINT/ingredients/expiring'
        '?user_id=${Uri.encodeComponent(userId)}'
        '&expire_within=$days',
  );
  final res = await http.get(uri);
  if (res.statusCode == 200) {
    final jsonBody = jsonDecode(utf8.decode(res.bodyBytes)) as Map<
        String,
        dynamic>;
    return jsonBody['notice'] as String;
  } else {
    throw Exception('만료 알림 불러오기 실패 (${res.statusCode})');
  }
}

/// 공지사항 모델
class Post {
  final int id;
  final String title;
  final DateTime date;

  Post({required this.id, required this.title, required this.date});
}

/// 오늘의 메뉴 모델
class Menu {
  final String name;
  final String imageUrl;

  Menu({required this.name, required this.imageUrl});
}

/// 더미 데이터 서비스
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

  static Future<Menu> getTodayMenu() async {
    final candidates = [
      Menu(name: '토마토 스프 파스타', imageUrl: 'https://via.placeholder.com/100'),
      Menu(name: '크림 리조또', imageUrl: 'https://via.placeholder.com/100'),
      Menu(name: '카레 라이스', imageUrl: 'https://via.placeholder.com/100'),
    ];
    await Future.delayed(const Duration(milliseconds: 300));
    return candidates[Random().nextInt(candidates.length)];
  }
}

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<String> _expireNoticeFuture;
  late Future<List<Post>> _postsFuture;
  late Future<Menu> _menuFuture;
  List<String> _toBuy = [];

  @override
  void initState() {
    super.initState();
    _expireNoticeFuture = fetchExpireNotice(widget.userId, 7);
    _loadToBuy(); // 로컬에 저장된 'toBuy' 리스트 불러오기
    _postsFuture = DataService.fetchLatestPosts(4);
    _menuFuture = DataService.getTodayMenu();
  }

  // SharedPreferences에서 구매 예정 리스트 불러오기
  Future<void> _loadToBuy() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('toBuy') ?? [];
    setState(() => _toBuy = saved);
  }

  // SharedPreferences에 구매 예정 리스트 저장하기
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
      setState(() => _toBuy.add(input.trim()));
      await _saveToBuy();
    }
  }

  Future<void> _removeItem(String txt) async {
    setState(() => _toBuy.remove(txt));
    await _saveToBuy();
  }

  @override
  Widget build(BuildContext context) {
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
            // ── 만료 알림 영역 ──
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<String>(
                future: _expireNoticeFuture,
                builder: (ctx, snap) {
                  String notice;
                  if (snap.connectionState != ConnectionState.done) {
                    notice = '알림 로딩 중...';
                  } else if (snap.hasError) {
                    notice = '알림 불러오기 실패';
                  } else {
                    notice = snap.data!;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notice, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(formattedDate, style: const TextStyle(fontSize: 16)),
                    ],
                  );
                },
              ),
            ),

            // ── 메인 콘텐츠 스크롤 영역 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
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
                                          GestureDetector(
                                            onTap: () =>
                                                Navigator.push(
                                                  ctx,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          NoticeBoard(
                                                              noticeId: p.id)),
                                                ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(vertical: 4.0),
                                              child: Text(p.title,
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      decoration: TextDecoration
                                                          .none)),
                                            ),
                                          ))
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('오늘의 메뉴',
                                    style:
                                    TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                FutureBuilder<Menu>(
                                  future: _menuFuture,
                                  builder: (ctx, snap) {
                                    if (snap.connectionState ==
                                        ConnectionState.done && snap.hasData) {
                                      return Column(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius
                                                  .circular(8),
                                            ),
                                            child: Image.network(
                                                snap.data!.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image)),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(snap.data!.name),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
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

            // ── 구매가 필요한 식재료 (하단 고정) ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
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
