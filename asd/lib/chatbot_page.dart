import 'package:flutter/material.dart';

class ChatBotPage extends StatelessWidget {
  const ChatBotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("챗봇")),
      body: const Center(
        child: Text("여기가 챗봇 화면입니다."),
      ),
    );
  }
}
