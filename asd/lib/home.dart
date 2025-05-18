// lib/home.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yolo/food_ingredient_detection_page.dart';
import 'package:yolo/notice_page.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'recipe.dart'; // RecipePage
import 'manage.dart'; // ManagePage
import 'login_page.dart'; // LoginPage (로그아웃 후 이동할 페이지)
=======
import 'recipe.dart'; // recipe.dart의 RecipePage를 가져옵니다
import 'manage.dart'; //
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
import 'recipe.dart'; // recipe.dart의 RecipePage를 가져옵니다
import 'manage.dart'; //
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
import 'recipe.dart'; // recipe.dart의 RecipePage를 가져옵니다
import 'manage.dart'; //
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)

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

/// 데이터 서비스 (더미)
class DataService {
  static Future<List<Post>> fetchLatestPosts(int count) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
      count,
      (i) => Post(
        id: count - i,
        title: '공지 ${count - i}',
        date: DateTime.now().subtract(Duration(days: i)),
      ),
    );
=======
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
        count,
        (i) => Post(
              id: count - i,
              title: '공지 ${count - i}',
              date: DateTime.now().subtract(Duration(days: i)),
            ));
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
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

/// 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Post>> _postsFuture;
  late Future<Menu> _menuFuture;
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  bool _showLogout = false; // ← 로그아웃 버튼 표시 여부
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)

  @override
  void initState() {
    super.initState();
    _postsFuture = DataService.fetchLatestPosts(4);
    _menuFuture = DataService.getTodayMenu();
  }

  @override
  Widget build(BuildContext context) {
    final expiredNotice = '바나나 소비기한 임박 2025-05-21';
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    final formattedDate =
        DateFormat('EEEE d MMMM y HH:mm').format(DateTime.now());
=======
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE d MMMM y HH:mm').format(now);
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE d MMMM y HH:mm').format(now);
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE d MMMM y HH:mm').format(now);
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
              // ─── 상단 알림 + 아이콘들 ───
=======
              // 상단 알림 + 아이콘
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
              // 상단 알림 + 아이콘
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
              // 상단 알림 + 아이콘
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expiredNotice,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {},
                  ),
                ],
              ),

              const SizedBox(height: 8),
              // 날짜/시간 표시
              Center(
                child: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 24),
              // 중앙 버튼 3개
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavButton(
                    icon: Icons.emoji_food_beverage,
                    label: '재료',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const App()),
                      );
                    },
                  ),
                  _NavButton(
                    icon: Icons.kitchen,
                    label: '냉장고 관리',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManagePage()),
                      );
                    },
                  ),
                  _NavButton(
                    icon: Icons.menu_book,
                    label: '레시피',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecipePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // 공지사항 + 오늘의 메뉴
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 공지사항
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '공지사항',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<List<Post>>(
                          future: _postsFuture,
                          builder: (context, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snap.hasError || !snap.hasData) {
                              return const Text('공지 로드 실패');
                            }
                            final posts = snap.data!;
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, i) {
                                return ListTile(
                                  title: Text(posts[i].title),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
                                        builder: (_) => NoticeBoard(
                                            noticeId: posts.length - i),
=======
                                        builder: (context) => NoticeBoard(
                                            noticeId:
                                                posts.length - i), // ID는 1부터 시작
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
                                        builder: (context) => NoticeBoard(
                                            noticeId:
                                                posts.length - i), // ID는 1부터 시작
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
                                        builder: (context) => NoticeBoard(
                                            noticeId:
                                                posts.length - i), // ID는 1부터 시작
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),
                  // 오늘의 메뉴
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '오늘의 메뉴',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<Menu>(
                          future: _menuFuture,
                          builder: (context, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snap.hasError || !snap.hasData) {
                              return const Text('메뉴 로드 실패');
                            }
                            final menu = snap.data!;
                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // 상세 레시피 코드
                                  },
                                ),
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      menu.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
                                            child: Icon(Icons.broken_image,
                                                size: 48, color: Colors.grey),
=======
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
=======
>>>>>>> parent of 41070ffb (로그아웃 버튼 추가)
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(menu.name),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 네비게이션 버튼 위젯
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
