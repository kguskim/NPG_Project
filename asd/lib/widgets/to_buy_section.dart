import 'package:flutter/material.dart';

class ToBuySection extends StatelessWidget {
  final List<String> items;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

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
        // 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '구매가 필요한 식재료',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
          ],
        ),
        const SizedBox(height: 8),
        // 고정 크기 박스 + 내부 스크롤
        Container(
          width: double.infinity,
          // 1) 세로 길이 고정
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: items.isEmpty
              ? const Center(child: Text('추가된 식재료가 없습니다.'))
              : Scrollbar(
            // 스크롤바 보이도록
            thumbVisibility: true,
            child: SingleChildScrollView(
              // 2) 내용이 container 높이를 넘으면 세로 스크롤
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
