// lib/home.dart
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // 더 이상 사용하지 않으므로 주석 처리 또는 삭제 가능
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

// [✅ 추가] 소비기한 임박 식재료 모델
class ExpiringIngredient {
  final String name;
  final int daysLeft; // 남은 일수

  ExpiringIngredient({required this.name, required this.daysLeft});

  // API 응답(JSON)으로부터 ExpiringIngredient 객체를 생성하는 팩토리 생성자
  factory ExpiringIngredient.fromJson(Map<String, dynamic> json) {
    // API 응답에 'expire_date' 필드가 'YYYY-MM-DD' 형식으로 온다고 가정
    final expireDate = DateTime.parse(json['expire_date'] as String);
    // 현재 날짜와 소비기한 날짜의 차이를 계산
    final daysLeft = expireDate.difference(DateTime.now()).inDays;

    return ExpiringIngredient(
      name: json['ingredient_name'] as String,
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

// [🔄 수정] 소비기한 임박 식재료 목록을 가져오는 API 호출 함수
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
    // 각 JSON 객체를 ExpiringIngredient 모델로 변환하여 리스트로 반환
    return data.map((json) => ExpiringIngredient.fromJson(json)).toList();
  } else {
    throw Exception('소비기한 임박 식재료 불러오기 실패 (${res.statusCode})');
  }
}

/// 오늘의 메뉴를 TodayRecipeModel 로 가져오는 함수
Future<TodayRecipeModel> fetchTodayRecipe(String userId) async {
  //  URL 구성: baseUrl + '/recipes/recommend/today' + userId 쿼리 파라미터
  final uri = Uri.parse('${ApiConfig.baseUrl}/recipes/recommend/today');
  // 2) GET 요청 보내기
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      // 필요하다면 Authorization 등 헤더 추가
    },
  );
  // 3) 응답 상태 코드 확인
  if (response.statusCode == 200) {
    // 4) 응답 본문을 JSON 파싱 후 TodayRecipeModel 생성
    final Map<String, dynamic> jsonMap =
        jsonDecode(utf8.decode(response.bodyBytes));
    return TodayRecipeModel.fromJson(jsonMap);
  } else {
    // 에러가 났다면 예외 던지기
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
      // 필요하다면 Authorization 등 헤더 추가
    },
  );

  if (response.statusCode == 200) {
    // 서버에서 [{id:1, title:"...", date:"2025-06-09T10:00:00Z"}, ...] 형태로 내려온다고 가정
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
  // [🔄 수정] Future<String> -> Future<List<ExpiringIngredient>>
  late Future<List<ExpiringIngredient>> _expiringIngredientsFuture;
  late Future<Menu> _menuFuture;
  List<String> _toBuy = [];

  @override
  void initState() {
    super.initState();
    _loadToBuy();
    // [🔄 수정] fetchExpireNotice -> fetchExpiringIngredients 호출
    _expiringIngredientsFuture = fetchExpiringIngredients(widget.userId, 7);
    _postsFuture = DataService.fetchLatestPosts(4);
    _menuFuture = DataService.getTodayMenu();
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
    // [❌ 삭제] final nowTxt = DateFormat('EEEE d MMMM y HH:mm').format(DateTime.now());

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
            // [🔄 수정] 만료 알림 영역 UI 전체 변경
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FutureBuilder<List<ExpiringIngredient>>(
                future: _expiringIngredientsFuture,
                builder: (ctx, snap) {
                  // 로딩 중일 때
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // 에러가 발생했을 때
                  if (snap.hasError) {
                    return Text('알림을 불러오는 중 오류가 발생했습니다.',
                        style: TextStyle(color: Colors.red.shade700));
                  }
                  // 데이터가 없거나 비어있을 때
                  final ingredients = snap.data;
                  if (ingredients == null || ingredients.isEmpty) {
                    return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green),
                            SizedBox(width: 8),
                            Text('소비기한이 임박한 식재료가 없습니다.'),
                          ],
                        ));
                  }

                  // 데이터가 있을 때 상세 UI 표시
                  return Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '소비기한 임박!',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 식재료 목록 (최대 3개까지)
                        ...ingredients.take(3).map((item) {
                          final dDay = item.daysLeft <= 0
                              ? '오늘까지!'
                              : 'D-${item.daysLeft}';
                          return Padding(
                            padding:
                                const EdgeInsets.only(left: 28.0, top: 4.0),
                            child: Text(
                              '• ${item.name}: $dDay',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        // 3개보다 많으면 개수 표시
                        if (ingredients.length > 3)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 28.0, top: 4.0),
                            child: Text('...외 ${ingredients.length - 3}개',
                                style: const TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── 나머지 홈 화면 ──
            // ─── 메인 스크롤 영역 ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 네비 버튼
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

                    // ─── 공지사항 영역 ───
                    IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // 공지사항
                          Expanded(
                            child: Container(
                              // Container로 감싸서 스타일 적용
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
                                  const SizedBox(height: 12), // 여백 살짝 조정
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
                                                        .ellipsis, // 글자가 길면 ... 처리
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
                          const SizedBox(width: 16), // 공지사항과 메뉴 사이 간격 추가
                          // ─── 오늘의 메뉴 영역 ───
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatBotPage(userId: widget.userId), // ✅ const 제거
            ),
          );
        },
        backgroundColor: Colors.blue, // 버튼 색
        child: const Icon(Icons.chat), // 채팅 아이콘
      ),
    );
  }
}

// 수정된 코드
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
        // GestureDetector의 유일한 child
        // 아이콘 사이즈 고정
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
        // Column을 Container의 child로 이동
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