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
  final String user_id;
  final int ingredient_id;
  final String imageUrl;
  final int fridge_id;
  final int area_id;
  final String alias;
  final int quantity;
  final String purchase_date;
  final String expiration_date;

  FridgeItem(
      {required this.user_id,
      required this.imageUrl,
      required this.ingredient_id,
      required this.fridge_id,
      required this.area_id,
      required this.alias,
      required this.quantity,
      required this.expiration_date,
      required this.purchase_date});

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
        user_id: json['user_id'].toString(),
        ingredient_id: json['ingredient_id'],
        imageUrl: json['image'],
        fridge_id: json['fridge_id'],
        area_id: json['area_id'],
        alias: json['alias'],
        quantity: json['quantity'],
        expiration_date: json['expiration_date'],
        purchase_date: json['purchase_date']);
  }

  FridgeItem copyWith({
    String? id,
    String? imageUrl,
    int? ingredient_id,
  }) {
    return FridgeItem(
        user_id: id ?? this.user_id,
        imageUrl: imageUrl ?? this.imageUrl,
        ingredient_id: ingredient_id ?? this.ingredient_id,
        fridge_id: fridge_id ?? this.fridge_id,
        area_id: area_id ?? this.area_id,
        alias: alias ?? this.alias,
        quantity: quantity ?? this.quantity,
        expiration_date: expiration_date ?? this.expiration_date,
        purchase_date: purchase_date ?? this.purchase_date);
  }
}

const Map<int, String> fridgeIdToName = {
  0: 'SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L',
  1: 'LG 모던엣지 냉장고 462L',
  2: '신규 냉장고',
};

// 예시 매핑 (서버 ID → UI에서 사용하는 이름)
const Map<int, Map<int, String>> areaIdToName = {
  0: {1: '냉장실', 2: '냉동실', 3: '냉장실 문칸'},
  1: {1: '냉장실', 2: '냉동실', 3: '냉장실 문칸'},
  2: {1: '냉장실', 2: '냉동실', 3: '문칸 상단', 4: '문칸 하단'},
};

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
      'https://a4a5-121-188-29-7.ngrok-free.app/ingredients?user_id=${widget.userId}',
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
    const baseUrl = 'https://a4a5-121-188-29-7.ngrok-free.app';

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

    // ✅ 현재 냉장고와 현재 섹션(area)에 해당하는 아이템만 필터링
    final filteredItems = items.where((item) {
      final itemFridgeName = fridgeIdToName[item.fridge_id];
      return itemFridgeName == _selectedFridge &&
          item.area_id == _currentCompartment + 1;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalH = constraints.maxHeight;
        final cellH = (totalH - (config.rows - 1) * spacing - 2 * borderWidth) /
            config.rows;

        // 최대 3개씩 묶어서 그룹화
        final groupedItems = <List<FridgeItem>>[];
        for (var i = 0; i < filteredItems.length; i += 3) {
          groupedItems.add(filteredItems.sublist(
            i,
            i + 3 > filteredItems.length ? filteredItems.length : i + 3,
          ));
        }

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
            final group = idx < groupedItems.length ? groupedItems[idx] : [];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: borderWidth,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: group.map((item) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _showItemDetailDialog(item),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildImage(item.imageUrl),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
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
        TextEditingController(text: utf8.decode(item.alias.codeUnits));
    final nameCtrl = TextEditingController(text: item.user_id);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final categoryCtrl = TextEditingController(text: '');
    final boughtCtrl =
        TextEditingController(text: utf8.decode(item.purchase_date.codeUnits));
    final expireCtrl = TextEditingController(
        text: utf8.decode(item.expiration_date.codeUnits));
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
                  decoration: const InputDecoration(labelText: '식재료명')),
              TextFormField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '수량')),
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
    final uri = Uri.parse(
        'https://a4a5-121-188-29-7.ngrok-free.app/ingredients/${item.ingredient_id}');
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
