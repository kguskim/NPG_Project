// widgets/to_buy_section.dart

import 'package:flutter/material.dart';

class ToBuySection extends StatelessWidget {
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const ToBuySection({
    Key? key,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더: 제목 + 추가 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '구매할 식재료',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 내용 박스: 세로 높이 고정, 내부 스크롤, 한 줄에 여러 개 배치
        Container(
          width: double.infinity,
          height: 160, // 세로 길이 완전 고정
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: items.isEmpty
              ? const Center(child: Text('추가된 식재료가 없습니다.'))
              : Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,    // 칩 간 가로 간격
                runSpacing: 4, // 칩 간 세로 간격
                children: items.map((item) {
                  return Chip(
                    label: Text(item),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => onRemove(item),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
