// lib/today_detailed_recipe.dart

import 'package:flutter/material.dart';

/// 상세 레시피 페이지
/// (항상 3쌍의 이미지↔설명이 교차해서 나오도록 강제)
class TodayDetailedRecipePage extends StatelessWidget {
  /// 각 단계별 이미지 URL 리스트
  final List<String> imageUrls;

  /// 각 단계별 설명 리스트
  final List<String> steps;

  /// 교차해서 보여줄 쌍의 개수 (여기서는 3쌍)
  static const int _pairCount = 3;

  const TodayDetailedRecipePage({
    Key? key,
    required this.imageUrls,
    required this.steps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 총 항목 수 = (이미지+설명) * _pairCount
    final int itemCount = _pairCount * 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세 레시피'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: itemCount,
          itemBuilder: (context, idx) {
            // pairIndex = 0,1,2 ...
            final int pairIndex = idx ~/ 2;

            // 짝수 idx → 이미지
            if (idx % 2 == 0) {
              // 실제 이미지가 있으면 사용, 없으면 플레이스홀더 URL 출력
              final imageUrl = pairIndex < imageUrls.length
                  ? imageUrls[pairIndex]
                  : 'https://via.placeholder.com/400x200.png?text=Step+${pairIndex +
                  1}';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      height: 200,
                      errorBuilder: (_, __, ___) =>
                          Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }

            // 홀수 idx → 설명
            else {
              final stepText = pairIndex < steps.length
                  ? steps[pairIndex]
                  : '${pairIndex + 1}. 자세한 설명이 없습니다.';

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  stepText,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
