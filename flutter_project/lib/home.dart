// lib/home.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'recipe.dart'; // recipe.dart의 RecipePage를 가져옵니다
import 'manage.dart';
import 'notice.dart'; 
// import 'today_recipe.dart'; 서버 연동 후 사용
// import 'models/recipe.dart'; 서버 연동 후 사용

class DataService {
  static Future<List<Notice>> fetchLatestPosts(int count) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(count, (i) => Notice(
      id: count - i,
      title: '공지 ${count - i}',
      createdAt: DateTime.now().subtract(Duration(days: i)),
    ));
  }
}

final List<Map<String, String>> dummyRecipes = [
  {'name': '토마토 스프 파스타', 'description': '부드럽고 고소한 풍미 가득',
    'imageUrl': 'https://via.placeholder.com/100'},
  {'name': '크림 리조또', 'description': '부드럽고 고소한 풍미 가득',
    'imageUrl': 'https://via.placeholder.com/100'},
  {'name': '카레 라이스', 'description': '부드럽고 고소한 풍미 가득',
    'imageUrl': 'https://via.placeholder.com/100'},
];

/// 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Notice>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _noticesFuture = DataService.fetchLatestPosts(4);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE d MMMM y HH:mm').format(now);

    final List<Map<String, dynamic>> dummyIngredients = [
      {'name': '전복', 'expiration': DateTime(2025, 05, 22)},
      {'name': '사과', 'expiration': DateTime(2025, 05, 28)},
      {'name': '소고기', 'expiration': DateTime(2025, 05, 21)},
    ]; //유통기한 임박 식재료 더미 리스트

    final soonToExpire = dummyIngredients.where((item) {
      final diff = item['expiration'].difference(now).inDays;
      return diff >= 0 && diff <= 3;
    }).toList(); //유통기한 3일 이내 재료 추출

    final dateFormat = DateFormat('yyyy-MM-dd');
    final expiredNotice = soonToExpire.isNotEmpty
        ? soonToExpire.map((item) {
      final name = item['name'];
      final date = dateFormat.format(item['expiration']);
      return '$name 소비기한 임박 $date';
    }).join('\n')
        : '소비기한 임박 식재료 없음';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 알림 + 아이콘
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expiredNotice,
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () {},
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
                      // TODO: 재료 페이지로 네비게이션
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
                          builder: (_) => RecipePage.test(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // 공지사항 + 오늘의 메뉴
              SizedBox(
                height: 200,
                child: NoticeBoard(),
              ),

              // 오늘의 메뉴 더미데티어
              Builder(
                builder: (context) {
                  final today = DateTime.now();
                  final index = today.day % dummyRecipes.length;
                  final recipe = dummyRecipes[index];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '오늘의 메뉴',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          recipe['imageUrl']!,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 160,
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        recipe['name']!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe['description']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  );
                },
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
