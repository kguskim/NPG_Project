// ✅ 'dart:convert', 'http', 'constants'를 import 합니다.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yolo/config/constants.dart'; // ApiConfig를 사용하기 위해 import

import 'chatbot_service.dart'; // 챗봇 서비스
// ❌ 'database_helper.dart'는 더 이상 필요 없습니다.

class ChatBotPage extends StatefulWidget {
  final String userId;
  const ChatBotPage({super.key, required this.userId});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<Map<String, dynamic>> _messages = [
    {
      "text": "안녕하세요! 재고 기반으로 레시피 추천, 재료 위치 찾기 등이 가능합니다.",
      "isMe": false
    },
  ];
  final TextEditingController _controller = TextEditingController();
  final ChatbotService _chatbotService = ChatbotService();
  bool _isLoading = false;

  // ✅ [수정됨] 로컬 DB(_getLocalIngredients) 대신
  //          서버 API(_getServerIngredients)에서 재고를 가져오는 함수
  Future<List<Map<String, dynamic>>> _getServerIngredients(String userId) async {
    // manage.dart와 동일하게 ApiConfig.baseUrl을 사용합니다.
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/ingredients?user_id=${widget.userId}',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decoded);

        // AI가 JSON을 직접 처리할 수 있도록 List<Map<String, dynamic>>으로 반환
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return []; // 서버가 200이 아니면 빈 리스트 반환
    } catch (e) {
      throw Exception('서버에서 식재료를 불러올 수 없습니다: $e');
    }
  }

  // ✅ [수정됨] _getServerIngredients를 호출하도록 변경
  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isLoading) return;
    final userInput = _controller.text.trim();

    setState(() {
      _messages.add({"text": userInput, "isMe": true});
      _isLoading = true;
      _messages.add({"text": "...", "isMe": false});
      _controller.clear();
    });

    try {
      // 1. (수정됨) 로컬 DB 대신 서버에서 재고 가져오기
      final List<Map<String, dynamic>> currentIngredients =
          await _getServerIngredients(widget.userId); // <--- 수정된 부분

      // [디버깅 코드] AI에게 전달할 (서버) 식재료 목록을 콘솔에 출력
      print('--- [Debug] AI에게 전달할 (서버) 식재료 목록 ---');
      print(currentIngredients);
      print('-----------------------------------------');

      // 2. 재고 + 질문을 AI 서버로 전송
      final apiResponse =
          await _chatbotService.getChatResponse(userInput, currentIngredients);

      // 3. AI의 답변을 화면에 표시
      setState(() {
        _messages.removeLast(); // "..." 제거
        _messages.add({"text": apiResponse, "isMe": false});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeLast(); // "..." 제거
        _messages.add({"text": "오류가 발생했습니다: $e", "isMe": false});
        _isLoading = false;
      });
    }
  }

  // UI를 그리는 build 메서드 (변경 없음)
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
                    child: msg["text"] == "..."
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
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
                    enabled: !_isLoading,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _isLoading ? null : _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}