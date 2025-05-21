// lib/manage_page.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
/// 주로 서버에서 받은 JSON 데이터를 다루기 위해 사용
class FridgeItem {
  final String id;
  final String imageUrl;
  final int ingredient_id;

  FridgeItem(
      {required this.id, required this.imageUrl, required this.ingredient_id});

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
        id: json['user_id'].toString(),
        imageUrl: json['image'],
        ingredient_id: json['ingredient_id']);
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
  // 드롭다운 목록
  late final List<String> _fridges = fridges;

  // 현재 선택된 냉장고 (SharedPreferences에서 복원)
  String _selectedFridge = fridges.first;

  // compartment 인덱스
  int _currentCompartment = 0;

  // compartment 목록
  List<String> get _compartments =>
      fridgeLayouts[_selectedFridge]?.keys.toList() ?? [];

  // 서버에서 받아올 Future
  late Future<List<FridgeItem>> _itemsFuture;

  // 상태 초기화
  @override
  void initState() {
    super.initState();
    _initSelectedFridge();
  }

  /// 마지막 선택값을 SharedPreferences에서 복원하고 아이템 로드
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

  /// 현재 선택된 냉장고와 compartment로 아이템 로드
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
        'https://baa8-121-188-29-7.ngrok-free.app/ingredients?user_id=${widget.userId}');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => FridgeItem.fromJson(e)).toList();
    }
    return [];
  }

  /// 아이템 삭제
  Future<void> _deleteItem(String id) async {
    showSnackBar(context, new Text(id));
    final uri =
        Uri.parse('https://baa8-121-188-29-7.ngrok-free.app/ingredients/$id');
    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      _loadItems();
    }
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
      );
    } else {
      final filePath = url.replaceFirst(RegExp(r'^file://'), '');
      final file = File(filePath);
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // 파일이 없거나 접근 불가할 때 placeholder
        errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
      );
    }
  }

  Widget _buildPartitionWithItems(List<FridgeItem> items) {
    final section =
        _compartments.isNotEmpty ? _compartments[_currentCompartment] : '';
    final config = fridgeLayouts[_selectedFridge]?[section];
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
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildImage(item.imageUrl),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _deleteItem(item.ingredient_id.toString()),
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
}
