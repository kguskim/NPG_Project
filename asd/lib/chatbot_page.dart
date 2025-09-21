import 'dart:math';
import 'package:flutter/material.dart';
import 'models/recipe_model.dart';
import 'recipe.dart';
import 'detailed_recipe.dart';
import 'database_helper.dart'; // ✅ 1. 데이터베이스 헬퍼 import 추가

class ChatBotPage extends StatefulWidget {
  final String userId;
  const ChatBotPage({super.key, required this.userId});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<Map<String, dynamic>> _messages = [
    // ✅ 2. 초기 안내 메시지 수정
    {
      "text": "안녕하세요! '레시피 추천' 또는 '사과는 어디에 있어?' 와 같이 질문해주세요.",
      "isMe": false
    },
  ];
  final TextEditingController _controller = TextEditingController();

  // ✅ 3. 메시지 전송 로직 전체를 새롭게 교체
  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final userInput = _controller.text.trim();

    setState(() {
      _messages.add({"text": userInput, "isMe": true});
      _controller.clear();
    });

    // 1. "레시피 추천" 기능
    if (userInput == "레시피 추천") {
      await _recommendRecipe();
      return;
    }

    // 2. "00은/는 어디에 있어?" 질문 패턴 확인
    final RegExp regExp = RegExp(r"(.+?)(은|는)\s+어디에\s?(있어|있나요|있어요)\??$");
    final Match? match = regExp.firstMatch(userInput);

    if (match != null) {
      final ingredientName = match.group(1)!;
      await _findIngredientLocation(ingredientName);
      return;
    }

    // 3. 위 조건에 해당하지 않는 경우 기본 응답
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({"text": "죄송하지만 이해하지 못했어요.", "isMe": false});
      });
    });
  }

  // ✅ 4. 클래스 내부에 아래 새로운 함수 3개 추가
  // 레시피 추천 로직
  Future<void> _recommendRecipe() async {
    try {
      setState(() {
        _messages.add({"text": "추천 레시피를 찾고 있습니다.", "isMe": false});
      });

      final recipes = await fetchUserRecipes(widget.userId);
      if (recipes.isNotEmpty) {
        final random = Random();
        final recipe = recipes[random.nextInt(recipes.length)];

        await Future.delayed(const Duration(milliseconds: 800));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailedRecipePage(
              imageUrls: recipe.stepImages,
              steps: recipe.stepDetails,
            ),
          ),
        );
      } else {
        setState(() {
          _messages.add({"text": "추천 레시피가 없습니다.", "isMe": false});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"text": "레시피를 불러오는 데 실패했습니다: $e", "isMe": false});
      });
    }
  }

  // 식재료 위치 찾기 로직
  Future<void> _findIngredientLocation(String ingredientName) async {
    try {
      final result = await DatabaseHelper.instance.findIngredientLocation(ingredientName);

      if (result != null) {
        final String foundName = result['name'];
        final String areaId = result['area_id'];
        final String particle = _getParticle(foundName);
        setState(() {
          _messages.add({"text": "$foundName$particle $areaId 에 있어요.", "isMe": false});
        });
      } else {
        setState(() {
          _messages.add({"text": "'$ingredientName'(와)과 일치하거나 유사한 식재료를 찾을 수 없어요.", "isMe": false});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"text": "검색 중 오류가 발생했습니다: $e", "isMe": false});
      });
    }
  }

  // 단어 받침 확인 로직
  String _getParticle(String word) {
    if (word.isEmpty) return '은';
    final lastChar = word.runes.last;
    if (lastChar >= 0xAC00 && lastChar <= 0xD7A3) {
      final bool hasJongseong = (lastChar - 0xAC00) % 28 != 0;
      return hasJongseong ? "은" : "는";
    }
    return "은";
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