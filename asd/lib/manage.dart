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
  'SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L': {
    '냉장실':    GridConfig(5, 1),
    '냉동실':    GridConfig(3, 1),
    '냉장실 문칸': GridConfig(3, 1)
  },
  'LG 모던엣지 냉장고 462L': {
    '냉장실':    GridConfig(5, 1),
    '냉동실':    GridConfig(3, 1),
    '냉장실 문칸': GridConfig(4, 2)
  },
  '신규 냉장고': {
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
  final TextEditingController _searchController = TextEditingController();
  // 냉장고 종류 드롭다운
  final List<String> _fridges = ['SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L', 'LG 모던엣지 냉장고 462L', '친구 냉장고'];
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

  /// GridView 기반 칸막이 + 아이템 매핑
  /// GridView + LayoutBuilder 기반 칸막이 + 아이템 매핑
  Widget _buildPartitionWithItems(List<FridgeItem> items) {
    final section     = _compartments[_currentCompartment];
    final config      = fridgeLayouts[_selectedFridge]![section]!;
    const spacing     = 12.0;  // 셀 간격
    const borderWidth = 3.0;   // 셀 경계선 두께

    return LayoutBuilder(
      builder: (context, constraints) {
        // 전체 그리드 높이에서 스페이싱과 테두리 모두 뺀 뒤, 행 수로 나눠서 셀 높이 계산
        final totalH    = constraints.maxHeight;
        final rows      = config.rows;
        final cellH     = (totalH - (rows - 1) * spacing - 2 * borderWidth) / rows;

        return GridView.builder(
          // 스크롤은 막아서 고정된 높이 안에서 모두 보이게
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:    config.cols,      // 열 수
            crossAxisSpacing:  spacing,          // 열 간격
            mainAxisSpacing:   spacing,          // 행 간격
            mainAxisExtent:    cellH,            // 셀 높이를 직접 지정
          ),
          itemCount: config.rows * config.cols,
          itemBuilder: (context, idx) {
            Widget cellContent;
            if (idx < items.length) {
              final item = items[idx];
              cellContent = Stack(
                children: [
                  // 이미지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // 삭제 버튼
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _deleteItem(item.id),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black45,
                        child: Icon(Icons.delete, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              cellContent = const SizedBox.shrink();
            }

            // 흰 배경 + 두꺼운 테두리 + 둥근 모서리
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: borderWidth),
                borderRadius: BorderRadius.circular(8),
              ),
              child: cellContent,
            );
          },
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '냉장고 종류',
                border: OutlineInputBorder(),
              ),
              items: _fridges.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              value: _selectedFridge,
              onChanged: (v) {
                if (v != null) {
                  _selectedFridge = v;
                  _loadItems();
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentCompartment > 0 ? () {
                    _currentCompartment--;
                    _loadItems();
                  } : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _compartments[_currentCompartment],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentCompartment < _compartments.length - 1 ? () {
                    _currentCompartment++;
                    _loadItems();
                  } : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
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
