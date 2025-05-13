// lib/manage_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// 칸막이 설정 클래스
class GridConfig {
  final int rows;
  final int cols;
  const GridConfig(this.rows, this.cols);
}

/// 냉장고 종류 & 구획별 행×열 설정
const Map<String, Map<String, GridConfig>> fridgeLayouts = {
  '집 냉장고': {
    '냉장실':    GridConfig(3, 2),
    '냉동실':    GridConfig(2, 2),
    '문칸 상단': GridConfig(1, 3),
    '문칸 하단': GridConfig(2, 3),
  },
  '사무실 냉장고': {
    '냉장실':    GridConfig(2, 3),
    '냉동실':    GridConfig(1, 2),
    '문칸 상단': GridConfig(1, 2),
    '문칸 하단': GridConfig(1, 2),
  },
  '친구 냉장고': {
    '냉장실':    GridConfig(2, 2),
    '냉동실':    GridConfig(2, 1),
    '문칸 상단': GridConfig(1, 2),
    '문칸 하단': GridConfig(1, 2),
  },
};

/// 냉장고 아이템 모델
class FridgeItem {
  final String id;
  final String imageUrl;
  FridgeItem({required this.id, required this.imageUrl});
  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      id: json['id'].toString(),
      imageUrl: json['imageUrl'],
    );
  }
}

/// 냉장고 관리 페이지
class ManagePage extends StatefulWidget {
  const ManagePage({Key? key}) : super(key: key);
  @override
  _ManagePageState createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  // 냉장고 종류 드롭다운
  final List<String> _fridges = ['집 냉장고', '사무실 냉장고', '친구 냉장고'];
  String _selectedFridge = '집 냉장고';

  // 컴파트먼트(구획)
  final List<String> _compartments = ['냉장실', '냉동실', '문칸 상단', '문칸 하단'];
  int _currentCompartment = 0;

  late Future<List<FridgeItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _itemsFuture = _fetchItemsFromServer(
        fridge: _selectedFridge,
        compartment: _compartments[_currentCompartment],
      );
    });
  }

  Future<List<FridgeItem>> _fetchItemsFromServer({
    required String fridge,
    required String compartment,
  }) async {
    final uri = Uri.parse(
        'https://example.com/api/fridge?name=$fridge&section=$compartment'
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => FridgeItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> _deleteItem(String id) async {
    final uri = Uri.parse('https://example.com/api/fridge/delete/$id');
    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      _loadItems();
    }
  }

  /// Table 기반 칸막이 + 아이템 매핑
  Widget _buildPartitionWithItems(List<FridgeItem> items) {
    final section = _compartments[_currentCompartment];
    final config = fridgeLayouts[_selectedFridge]![section]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final spacing = 8.0;
        final borderWidth = 2.0;
        final cellHeight = (totalHeight - // total available height
            (config.rows - 1) * spacing - // inside spacing
            2 * borderWidth) // top/bottom borders
            / config.rows;

        return Table(
          columnWidths: {
            for (int i = 0; i < config.cols; i++)
              i: const FlexColumnWidth(1),
          },
          border: TableBorder(
            top: BorderSide(color: Colors.grey.shade400, width: borderWidth),
            bottom: BorderSide(color: Colors.grey.shade400, width: borderWidth),
            left: BorderSide(color: Colors.grey.shade400, width: borderWidth),
            right: BorderSide(color: Colors.grey.shade400, width: borderWidth),
            horizontalInside: BorderSide(color: Colors.grey.shade400, width: borderWidth),
            verticalInside: BorderSide(color: Colors.grey.shade400, width: borderWidth),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: List.generate(config.rows, (r) {
            return TableRow(
              children: List.generate(config.cols, (c) {
                final idx = r * config.cols + c;
                Widget cell;
                if (idx < items.length) {
                  final item = items[idx];
                  cell = Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _deleteItem(item.id),
                          child: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  cell = const SizedBox.shrink();
                }
                return SizedBox(
                  height: cellHeight,
                  child: Padding(
                    padding: EdgeInsets.all(spacing / 2),
                    child: cell,
                  ),
                );
              }),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('식재료 관리'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 냉장고 선택 드롭다운
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '냉장고 종류',
                border: OutlineInputBorder(),
              ),
              items: _fridges
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              value: _selectedFridge,
              onChanged: (v) {
                if (v != null) {
                  _selectedFridge = v;
                  _loadItems();
                }
              },
            ),
            const SizedBox(height: 16),

            // 컴파트먼트 네비게이션
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentCompartment > 0
                      ? () {
                    _currentCompartment--;
                    _loadItems();
                  }
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _compartments[_currentCompartment],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentCompartment < _compartments.length - 1
                      ? () {
                    _currentCompartment++;
                    _loadItems();
                  }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 냉장고 모양 컨테이너 + Table 칸막이
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: FutureBuilder<List<FridgeItem>>(
                  future: _itemsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snap.data ?? [];
                    return _buildPartitionWithItems(items);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
