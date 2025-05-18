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
          constraints: const BoxConstraints(
            minHeight: 80,
            maxHeight: 160,  // 3~4줄 정도 보이도록
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: items.isEmpty
              ? const Center(child: Text('메모가 없습니다.'))
              : Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final txt = items[i];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('• $txt'),
                    GestureDetector(
                      onTap: () => onRemove(txt),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
