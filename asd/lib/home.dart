// lib/home.dart
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolo/chatbot_page.dart';
import 'package:yolo/food_ingredient_detection_page.dart';
import 'package:yolo/login_page.dart';
import 'package:yolo/manage.dart';
import 'package:yolo/notice_page.dart';
import 'package:yolo/recipe.dart';
import 'package:http/http.dart' as http;
import 'package:yolo/detailed_recipe.dart';
import 'widgets/to_buy_section.dart';
import 'models/today_recipe_model.dart';
import 'package:yolo/config/constants.dart';

// [✅ 수정] 소비기한 임박 식재료 모델 안정성 강화
class ExpiringIngredient {
  final String name;
  final int daysLeft; // 남은 일수

  ExpiringIngredient({required this.name, required this.daysLeft});

  // [✅ 수정] API 응답 오류에 더 강력하게 대응하는 팩토리 생성자
  factory ExpiringIngredient.fromJson(Map<String, dynamic> json) {
    final expireDateStr = json['expiration_date'] as String?;
    final ingredientName = json['ingredient_name'] as String?;

    // 날짜나 이름 데이터가 없으면 예외 발생
    if (expireDateStr == null || ingredientName == null) {
      throw const FormatException('Invalid ingredient data from API');
    }

    // 잘못된 날짜 형식에 대비해 tryParse 사용
    final expireDate = DateTime.tryParse(expireDateStr);
    if (expireDate == null) {
      // 파싱 실패 시 예외 발생
      throw FormatException('Invalid date format: $expireDateStr');
    }

    // 현재 날짜와 소비기한 날짜의 차이를 계산
    // 자정 기준으로 계산하기 위해 시/분/초를 0으로 초기화
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = expireDate.difference(today).inDays;

    return ExpiringIngredient(
      name: ingredientName,
      daysLeft: daysLeft,
    );
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

/// 더미 데이터 서비스 (공지사항)
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
      Menu(name: '크림 리조또', imageUrl: 'https://via.placeholder.com/100'),
      Menu(name: '카레 라이스', imageUrl: 'https://via.placeholder.com/100'),
    ];
    await Future.delayed(const Duration(milliseconds: 300));
    return candidates[Random().nextInt(candidates.length)];
  }
}

Future<List<ExpiringIngredient>> fetchExpiringIngredients(
    String userId, int days) async {
  final uri = Uri.parse(
    '${ApiConfig.baseUrl}/ingredients'
    '?user_id=${Uri.encodeComponent(userId)}'
    '&expire_within=$days',
  );
  final res = await http.get(uri, headers: {
    'Accept': 'application/json',
  });

  if (res.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((json) => ExpiringIngredient.fromJson(json)).toList();
  } else {
    throw Exception('소비기한 임박 식재료 불러오기 실패 (${res.statusCode})');
  }
}

/// 오늘의 메뉴를 TodayRecipeModel 로 가져오는 함수
Future<TodayRecipeModel> fetchTodayRecipe(String userId) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/recipes/recommend/today');
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
  );
  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonMap =
        jsonDecode(utf8.decode(response.bodyBytes));
    return TodayRecipeModel.fromJson(jsonMap);
  } else {
    throw Exception('오늘의 메뉴를 불러오는 데 실패했습니다 (status: ${response.statusCode})');
  }
}

/// 공지사항 가져오는 함수
Future<List<Post>> fetchAnnouncements() async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/notice');
  final response = await http.get(
    uri,
    headers: {
      'Accept': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((e) => Post(
              id: e['id'] as int,
              title: e['title'] as String,
              date: DateTime.parse(e['date'] as String),
            ))
        .toList();
  } else {
    throw Exception('공지사항을 불러오는 데 실패했습니다 (status: ${response.statusCode})');
  }
}

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Post>> _postsFuture;
  late Future<TodayRecipeModel> _todayFuture;
  late Future<List<ExpiringIngredient>> _expiringIngredientsFuture;
  late Future<Menu> _menuFuture;
  List<String> _toBuy = [];

  @override
  void initState() {
    super.initState();
    _loadToBuy();
    // 소비기한이 이미 지났을 수도 있으니 넉넉하게 30일 이내 만료되는 것들을 가져옵니다.
    _expiringIngredientsFuture = fetchExpiringIngredients(widget.userId, 30);
    _postsFuture = DataService.fetchLatestPosts(4);
    _menuFuture = DataService.getTodayMenu();
    _todayFuture = fetchTodayRecipe(widget.userId);
  }

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
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            TextButton(
                onPressed: () => Navigator.pop(context, text),
                child: const Text('추가')),
          ],
        );
      },
    );
    if (input != null && input.trim().isNotEmpty) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          Builder(builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.person),
              onPressed: () async {
                final button = ctx.findRenderObject() as RenderBox;
                final overlay =
                    Overlay.of(ctx)!.context.findRenderObject() as RenderBox;
                final pos =
                    button.localToGlobal(Offset.zero, ancestor: overlay);
                final selected = await showMenu<String>(
                  context: ctx,
                  position: RelativeRect.fromLTRB(
                    pos.dx,
                    pos.dy + button.size.height,
                    pos.dx + button.size.width,
                    pos.dy,
                  ),
                  items: [
                    const PopupMenuItem(value: 'logout', child: Text('LOGOUT'))
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
            // [✅✨ 수정 & 추가] 만료 알림 영역 UI 전체 변경
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FutureBuilder<List<ExpiringIngredient>>(
                future: _expiringIngredientsFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Text('알림을 불러오는 중 오류가 발생했습니다: ${snap.error}', // 에러 내용 표시
                        style: TextStyle(color: Colors.red.shade700));
                  }

                  final allIngredients = snap.data ?? [];

                  // ✨ 소비기한 지난 식재료와 임박한 식재료 분리
                  final expired = allIngredients.where((i) => i.daysLeft < 0).toList();
                  // 7일 이내 임박한 것만 필터링
                  final expiring = allIngredients.where((i) => i.daysLeft >= 0 && i.daysLeft <= 7).toList();

                  // 둘 다 없으면 안전 메시지 표시
                  if (expired.isEmpty && expiring.isEmpty) {
                    return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green),
                            SizedBox(width: 8),
                            Text('소비기한이 임박한 식재료가 없습니다.'),
                          ],
                        ));
                  }

                  // ✨ 분리된 목록을 표시하기 위해 Column 사용
                  return Column(
                    children: [
                      // ✨ 소비기한이 "지난" 식재료가 있으면 표시 (붉은색)
                      if (expired.isNotEmpty)
                        _buildNoticeCard(
                          title: '소비기한 만료!',
                          icon: Icons.error_outline,
                          iconColor: Colors.red,
                          bgColor: Colors.red.shade50,
                          borderColor: Colors.red.shade200,
                          ingredients: expired,
                        ),
                      // ✨ 두 알림 사이에 간격 추가
                      if (expired.isNotEmpty && expiring.isNotEmpty)
                        const SizedBox(height: 12),
                      // ✨ 소비기한이 "임박한" 식재료가 있으면 표시 (주황색)
                      if (expiring.isNotEmpty)
                        _buildNoticeCard(
                          title: '소비기한 임박!',
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orange,
                          bgColor: Colors.orange.shade50,
                          borderColor: Colors.orange.shade200,
                          ingredients: expiring,
                        ),
                    ],
                  );
                },
              ),
            ),

            // ── 나머지 홈 화면 ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavButton(
                          icon: Icons.emoji_food_beverage,
                          label: '재료',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => App(userId: widget.userId)),
                          ),
                        ),
                        _NavButton(
                          icon: Icons.kitchen,
                          label: '냉장고 관리',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ManagePage(userId: widget.userId)),
                          ),
                        ),
                        _NavButton(
                          icon: Icons.menu_book,
                          label: '레시피',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    RecipePage(userId: widget.userId)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('공지사항',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            snap.data!.asMap().entries.map((e) {
                                          final p = e.value;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              GestureDetector(
                                                onTap: () => Navigator.push(
                                                  ctx,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          NoticeBoard(
                                                              noticeId: p.id)),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4.0),
                                                  child: Text(
                                                    p.title,
                                                    style: const TextStyle(
                                                        decoration:
                                                            TextDecoration.none,
                                                        color: Colors.black),
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                              ),
                                              if (e.key < snap.data!.length - 1)
                                                const Divider(height: 1),
                                            ],
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  '오늘의 메뉴',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<TodayRecipeModel>(
                                  future: _todayFuture,
                                  builder: (ctx, snap) {
                                    if (snap.connectionState ==
                                        ConnectionState.waiting) {
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                today.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                        Icons.broken_image),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          today.title,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatBotPage(userId: widget.userId),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.chat),
      ),
    );
  }

  // [✨ 추가] 공통 알림 카드 위젯을 만드는 함수
  Widget _buildNoticeCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required List<ExpiringIngredient> ingredients,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor.withOpacity(0.9)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...ingredients.take(3).map((item) {
            String dDayText;
            if (item.daysLeft < 0) {
              // 소비기한 지남
              dDayText = 'D+${item.daysLeft.abs()}';
            } else if (item.daysLeft == 0) {
              // 오늘까지
              dDayText = '오늘까지!';
            } else {
              // D-day
              dDayText = 'D-${item.daysLeft}';
            }
            return Padding(
              padding: const EdgeInsets.only(left: 28.0, top: 4.0),
              child: Text('• ${item.name}: $dDayText', style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          if (ingredients.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 28.0, top: 4.0),
              child: Text('...외 ${ingredients.length - 3}개', style: const TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}

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
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3))
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}