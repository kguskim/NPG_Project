// lib/manage_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences에 저장된 마지막 선택된 냉장고 이름 키
const _kLastSelectedFridgeKey = 'last_selected_fridge';

void _saveFridgeName(String fridgeName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLastSelectedFridgeKey, fridgeName);
}

/// 칸막이 설정 클래스
class GridConfig {
  final int rows;
  final int cols;

  const GridConfig(this.rows, this.cols);
}

final List<String> fridges = [
  'SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L',
  'LG 모던엣지 냉장고 462L',
  '신규 냉장고'
];

/// 냉장고 종류 & 구획별 행×열 설정
const Map<String, Map<String, GridConfig>> fridgeLayouts = {
  'SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L': {
    '냉장실': GridConfig(5, 1),
    '냉동실': GridConfig(3, 1),
    '냉장실 문칸': GridConfig(3, 1)
  },
  'LG 모던엣지 냉장고 462L': {
    '냉장실': GridConfig(5, 1),
    '냉동실': GridConfig(3, 1),
    '냉장실 문칸': GridConfig(4, 2)
  },
  '신규 냉장고': {
    '냉장실': GridConfig(2, 2),
    '냉동실': GridConfig(2, 1),
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

  // 드롭다운 목록
  
  final List<String> _fridges = fridges;

  // 현재 선택된 냉장고 (기본값은 리스트 첫 번째)
  String _selectedFridge = fridges.first;

  // 현재 compartment 인덱스
  int _currentCompartment = 0;

  // compartment 목록
  List<String> get _compartments =>
      fridgeLayouts[_selectedFridge]?.keys.toList() ?? [];

  late Future<List<FridgeItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _initSelectedFridge();
  }

  /// SharedPreferences에서 마지막 선택된 냉장고를 로드하고,
  /// _selectedFridge에 설정한 뒤 _loadItems() 호출
  Future<void> _initSelectedFridge() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLastSelectedFridgeKey);
    if (saved != null && _fridges.contains(saved)) {
      _selectedFridge = saved;
    }
    // compartment 인덱스가 범위를 벗어나지 않도록 조정
    if (_currentCompartment >= _compartments.length) {
      _currentCompartment = 0;
    }
    _loadItems();
  }

  /// 현재 _selectedFridge와 _currentCompartment를 기반으로 서버에서 아이템 로드
  void _loadItems() {
    final section = _compartments.isNotEmpty
        ? _compartments[_currentCompartment]
        : '';
    _itemsFuture = _fetchItemsFromServer(
      fridge: _selectedFridge,
      compartment: section,
    );
    setState(() {});
  }

  Future<List<FridgeItem>> _fetchItemsFromServer({
    required String fridge,
    required String compartment,
  }) async {
    final uri = Uri.parse(
        'https://example.com/api/fridge?name=${Uri.encodeComponent(
            fridge)}&section=${Uri.encodeComponent(compartment)}');
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

  Widget _buildPartitionWithItems(List<FridgeItem> items) {
    final section = _compartments.isNotEmpty
        ? _compartments[_currentCompartment]
        : '';
    final config = fridgeLayouts[_selectedFridge]?[section];
    if (config == null) return const SizedBox.shrink();

    const spacing = 12.0;
    const borderWidth = 3.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalH = constraints.maxHeight;
        final cellH = (totalH -
            (config.rows - 1) * spacing -
            2 * borderWidth) /
            config.rows;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: config.cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cellH,
          ),
          itemCount: config.rows * config.cols,
          itemBuilder: (context, idx) {
            if (idx < items.length) {
              final item = items[idx];
              return Stack(
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
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _deleteItem(item.id),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black45,
                        child:
                        Icon(Icons.delete, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                  Border.all(color: Colors.grey.shade400, width: borderWidth),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox.shrink(),
              );
            }
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
              items: _fridges
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              value: _selectedFridge,
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedFridge = v;
                    _currentCompartment = 0;
                    _saveFridgeName(v);
                  });
                  _loadItems();
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentCompartment > 0
                      ? () {
                    setState(() {
                      _currentCompartment--;
                    });
                    _loadItems();
                  }
                      : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _compartments.isNotEmpty
                          ? _compartments[_currentCompartment]
                          : '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentCompartment < _compartments.length - 1
                      ? () {
                    setState(() {
                      _currentCompartment++;
                    });
                    _loadItems();
                  }
                      : null,
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
