import 'package:flutter/material.dart';
import 'package:npg/cameraPage.dart';
import 'package:npg/recipePage.dart';
import 'package:npg/refrigeratorPage.dart';
import 'clock.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 147, 221, 255), // 배경색 설정
      // 화면 중앙
      body: Center(
        // 세로 정렬
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬

          children: [
            // 시간 표시
            const Clock(),

            // 간격 띄우기
            SizedBox(height: 50),

            // 식재료 등록 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CameraPage()),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/IngredientsIco.png'),
                  const Text("식재료 등록"),
                ],
              ),
            ),

            // 간격 띄우기
            SizedBox(height: 30),

            // 식재료 관리 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RefrigeratorPage()),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/RefrigeratorIco.png'),
                  const Text('식재료 관리'),
                ],
              ),
            ),

            // 간격 띄우기
            SizedBox(height: 30),

            // 레시피 추천 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecipePage()),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/RecipeIco.png'),
                  const Text("레시피 추천"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
