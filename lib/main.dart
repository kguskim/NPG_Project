import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'homePage.dart';

// 앱 엔트리
void main() {
  runApp(const NpgProject());
}

// 루트 위젯
class NpgProject extends StatelessWidget {
  const NpgProject({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]); // 화면 세로 고정
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    ); // 화면 전체화면

    return MaterialApp(
      debugShowCheckedModeBanner: false, // 디버깅 모드 베나 표시
      home: HomePage(), // homePage.dart의
    );
  }
}
