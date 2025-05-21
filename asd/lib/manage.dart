// lib/manage.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yolo/login_page.dart';

/// SharedPreferences에 저장된 마지막 선택된 냉장고 이름 키
const _kLastSelectedFridgeKey = 'last_selected_fridge';

// 앱을 껐다 켜도 사용자가 마지막에 선택한 냉장고 이름을 기억해두는 함수
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

/// 냉장고 종류 이름 목록
final List<String> fridges = [
  'SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L',
  'LG 모던엣지 냉장고 462L',
  '신규 냉장고',
];

/// 냉장고 종류 & 구획별 행×열 설정
const Map<String, Map<String, GridConfig>> fridgeLayouts = {
  'SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L': {
    '냉장실': GridConfig(5, 1),
    '냉동실': GridConfig(3, 1),
    '냉장실 문칸': GridConfig(3, 1),
  },
  'LG 모던엣지 냉장고 462L': {
    '냉장실': GridConfig(5, 1),
    '냉동실': GridConfig(3, 1),
    '냉장실 문칸': GridConfig(4, 2),
  },
  '신규 냉장고': {
    '냉장실': GridConfig(2, 2),
    '냉동실': GridConfig(2, 1),
    '문칸 상단': GridConfig(1, 2),
    '문칸 하단': GridConfig(1, 2),
  },
};

/// 냉장고 안의 식재료나 물건 하나를 표현하는 모델 클래스입니다.
class FridgeItem {
  final String id;
  final int ingredient_id;
  final String imageUrl;
  

  FridgeItem({
    required this.id,
    required this.imageUrl,
    required this.ingredient_id,

  });

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      id: json['user_id'].toString(),
      imageUrl: json['image'],
      ingredient_id: json['ingredient_id'],
    );
  }

  FridgeItem copyWith({
    String? id,
    String? imageUrl,
    int? ingredient_id,
  }) {
    return FridgeItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredient_id: ingredient_id ?? this.ingredient_id,
    );
  }
}

/// 냉장고 관리 페이지
class ManagePage extends StatefulWidget {
  final String userId;
  const ManagePage({super.key, required this.userId});

  @override
  _ManagePageState createState() => _ManagePageState();
}

/// 냉장고 관리 STATE
class _ManagePageState extends State<ManagePage> {
  late final List<String> _fridges = fridges;
  String _selectedFridge = fridges.first;
  int _currentCompartment = 0;
  List<String> get _compartments =>
      fridgeLayouts[_selectedFridge]?.keys.toList() ?? [];
  late Future<List<FridgeItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _initSelectedFridge();
  }

  Future<void> _initSelectedFridge() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLastSelectedFridgeKey);
    if (saved != null && _fridges.contains(saved)) {
      _selectedFridge = saved;
    }
    if (_currentCompartment >= _compartments.length) {
      _currentCompartment = 0;
    }
    _loadItems();
  }

  void _loadItems() {
    final section =
        _compartments.isNotEmpty ? _compartments[_currentCompartment] : '';
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
      'https://baa8-121-188-29-7.ngrok-free.app/ingredients?user_id=${widget.userId}',
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => FridgeItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> _deleteItem(String id) async {
    final uri = Uri.parse(
      'https://baa8-121-188-29-7.ngrok-free.app/ingredients/$id',
    );
    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      _loadItems();
    }
  }

  Widget _buildImage(String imageUrl) {
    // 만약 imageUrl이 상대 경로로 오면, 전체 URL로 변환
    const baseUrl = 'https://baa8-121-188-29-7.ngrok-free.app';

    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '$baseUrl$imageUrl'; // 상대 경로 처리

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildPartitionWithItems(List<FridgeItem> items) {
    final config =
        fridgeLayouts[_selectedFridge]?[_compartments[_currentCompartment]];
    if (config == null) return const SizedBox.shrink();

    const spacing = 12.0;
    const borderWidth = 3.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalH = constraints.maxHeight;
        final cellH = (totalH - (config.rows - 1) * spacing - 2 * borderWidth) /
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
              return GestureDetector(
                onTap: () => _showItemDetailDialog(item),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildImage(item.imageUrl),
                    ),
                  ],
                ),
              );
            } else {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: Colors.grey.shade400, width: borderWidth),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                if (v == null) return;
                setState(() {
                  _selectedFridge = v;
                  _currentCompartment = 0;
                });
                _saveFridgeName(v);
                _loadItems();
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

  /// 선택된 식재료 정보 수정/삭제 다이얼로그
  void _showItemDetailDialog(FridgeItem item) {
    final aliasCtrl =
        TextEditingController(text: item.ingredient_id.toString());
    final nameCtrl = TextEditingController(text: item.id);
    final qtyCtrl = TextEditingController(text: '1');
    final categoryCtrl = TextEditingController(text: '');
    final boughtCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final expireCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd')
            .format(DateTime.now().add(Duration(days: 7))));
    final memoCtrl = TextEditingController(text: '');
    final areaCtrl = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('식재료 정보'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(item.imageUrl),
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: aliasCtrl,
                  decoration: const InputDecoration(labelText: 'Alias')),
              TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '식재료 명')),
              TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '수량')),
              TextFormField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: '카테고리')),
              TextFormField(
                  controller: boughtCtrl,
                  decoration:
                      const InputDecoration(labelText: '구매일자 (YYYY-MM-DD)')),
              TextFormField(
                  controller: expireCtrl,
                  decoration:
                      const InputDecoration(labelText: '소비기한 (YYYY-MM-DD)')),
              TextFormField(
                  controller: memoCtrl,
                  decoration: const InputDecoration(labelText: '메모'),
                  maxLines: 2),
              TextFormField(
                  controller: areaCtrl,
                  decoration: const InputDecoration(labelText: 'Area ID')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _deleteItem(item.ingredient_id.toString());
              Navigator.of(context).pop();
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: 서버에 업데이트 API 호출 (_updateItemOnServer)
              Navigator.of(context).pop();
              _loadItems();
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  /// 서버에 PATCH 요청으로 아이템 정보 업데이트
  Future<void> _updateItemOnServer(
      FridgeItem item, Map<String, dynamic> data) async {
    final uri =
        Uri.parse('https://your.api.com/ingredients/${item.ingredient_id}');
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      throw Exception('수정 실패: ${res.statusCode}');
    }
  }
}
