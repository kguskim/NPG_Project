import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  // 1. OpenAI API 엔드포인트
  static const String _apiEndpoint =
      'https://api.openai.com/v1/chat/completions';

  //
  // ⚠️⚠️ [보안 경고] ⚠️⚠️
  //
  // 이 API 키는 NPG님이 대화 중에 노출하신 키입니다.
  // 이 코드가 작동하는 것을 확인하신 후,
  // 즉시 OpenAI 대시보드에서 이 키를 삭제(Revoke)하고
  // 새 키로 교체하세요!
  //
  static const String _apiKey = 'your_api_key';

  // ✅ [최종 수정] 샘플 데이터를 100% 제거하고
  //          빈 리스트 '[]'를 올바르게 처리하도록 수정한 프롬프트
  String _buildSystemPrompt(List<Map<String, dynamic>> ingredients) {

    final ingredientsJsonString = jsonEncode(ingredients);

    return """
당신은 사용자의 냉장고 데이터를 분석하고 답변하는 '스마트 냉장고 비서'입니다.
당신은 "고정된 응답"이나 "기본 응답"을 **절대 하지 않습니다.**
당신의 답변은 **반드시** 아래 [현재 냉장고 재고] JSON 데이터를 기반으로, **오래 걸리더라도 정확하게 생성**해야 합니다.

**[매우 중요한 규칙 1]**
만약 [현재 냉장고 재고]가 `[]` (빈 리스트)라면, "현재 냉장고가 비어있습니다." 또는 "재고가 없습니다."라고 **사실대로** 답변해야 합니다.

**[매우 중요한 규칙 2]**
만약 [현재 냉장고 재고]가 비어있지 않다면 (`[]`가 아니라면), 사용자가 "뭐 있어?" 또는 "재고 알려줘"라고 물었을 때, `name` 또는 `alias`를 추출하여 "네, 현재 [A, B, C]가 있습니다."라고 **목록을 모두 말해야 합니다.**

[데이터 해석 가이드]
(사용자의 DB 스키마 기준)
* `ingredient_id`: 식재료의 고유 번호입니다.
* `name` (또는 `alias`): 식재료의 이름입니다.
* `area_id`: 식재료가 보관된 **위치**입니다.
* `quantity`: 수량입니다.
* `expiration_date`: 소비기한입니다.
* `purchase_date`: 구매일입니다.

---
[현재 냉장고 재고 (JSON 형식)]
$ingredientsJsonString
---

[질문 예시 및 올바른 답변 방식 (재고가 있을 경우에만 참고)]
* **사용자 질문:** "냉장고에 뭐 있어?"
* **올바른 답변 (데이터 활용):** "네, 현재 [재고 목록의 이름들]이 있습니다." (이름만 요약)

* **사용자 질문:** "[재료 이름] 어딨어?" (예: "양파 어딨어?")
* **올바른 답변 (데이터 활용):** "[재료 이름]은(는) [area_id에 해당하는 위치]에 있습니다." (`area_id` 정보 활용)

* **사용자 질문:** "[위치 이름]에 뭐 있어?" (예: "냉장실 1층에 뭐 있어?")
* **올바른 답변 (데이터 활용):** "[위치 이름]에는 [해당 위치의 재료 이름 목록]이 있습니다." (데이터 역추적)

* **사용자 질문:** "배 아플 때 뭐 먹어?" (재고와 무관한 질문)
* **올바른 답변 (일반 지식):** "배가 아플 때는 따뜻한 물이나 소화에 좋은 음식을 드시는 것이 좋습니다."

이제 위 [현재 냉장고 재고] 데이터를 완벽하게 분석하여 사용자의 다음 질문에 답변하세요.
""";
  }

  // OpenAI API에 질문을 전송하는 함수 (변경 없음)
  Future<String> getChatResponse(
      String userQuestion, List<Map<String, dynamic>> ingredients) async {
    try {
      final systemPrompt = _buildSystemPrompt(ingredients);

      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt
            },
            {
              'role': 'user',
              'content': userQuestion
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['choices'][0]['message']['content'];
      } else {
        return "AI API 오류: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "AI 통신 중 오류가 발생했습니다: $e";
    }
  }
}