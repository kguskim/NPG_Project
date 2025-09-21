import 'dart:math';
import 'package:flutter/material.dart';
import 'models/recipe_model.dart';
import 'recipe.dart'; // ✅ fetchUserRecipes 가져오기
import 'detailed_recipe.dart';
import 'database_helper.dart';

class ChatBotPage extends StatefulWidget {
  final String userId; // ✅ userId 필요
  const ChatBotPage({super.key, required this.userId});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<Map<String, dynamic>> _messages = [
    {"text": "안녕하세요! 무엇을 도와드릴까요?", "isMe": false},
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final userInput = _controller.text.trim();

    setState(() {
      _messages.add({"text": userInput, "isMe": true});
      _controller.clear();
    });

    if (userInput == "레시피 추천") {
      try {
        setState(() {
          _messages.add({"text": "추천 레시피를 표시합니다.", "isMe": false});
        });

        // ✅ 서버에서 추천 레시피 3개 가져오기
        final recipes = await fetchUserRecipes(widget.userId);
        if (recipes.isNotEmpty) {
          final random = Random();
          final recipe = recipes[random.nextInt(recipes.length)];

          // ✅ 상세 레시피 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailedRecipePage(
                imageUrls: recipe.stepImages,
                steps: recipe.stepDetails,
              ),
            ),
          );
          return;
        } else {
          setState(() {
            _messages.add({"text": "추천 레시피가 없습니다.", "isMe": false});
          });
        }
      } catch (e) {
        setState(() {
          _messages.add({"text": "레시피 불러오기 실패: $e", "isMe": false});
        });
      }
      return;
    }

    // 기본 응답
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({"text": "죄송하지만 이해하지 못했어요.", "isMe": false});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("챗봇")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg["isMe"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: msg["isMe"] ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "메시지를 입력하세요...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
