import 'package:flutter/material.dart';
import 'home.dart';
void main() {
  runApp(const MaterialApp(
    home: HomePage(),
  ));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(), 
    );
  }
} //테스트코드용
