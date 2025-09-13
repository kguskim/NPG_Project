import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolo/config/constants.dart';

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

const Map<String, List<String>> fridgeLayoutsNames = {
  'SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L': [
    '냉장실 1층',
    '냉장실 2층',
    '냉장실 3층',
    '냉장실 4층',
    '냉장실 5층',
    '냉동실 1층',
    '냉동실 2층',
    '냉동실 3층',
    '냉장실 문칸 1층',
    '냉장실 문칸 2층',
    '냉장실 문칸 3층',
  ],
  'LG 모던엣지 냉장고 462L': [
    '냉장실 1층',
    '냉장실 2층',
    '냉장실 3층',
    '냉장실 4층',
    '냉장실 5층',
    '냉동실 1층',
    '냉동실 2층',
    '냉동실 3층',
    '냉장실 문칸 1층 왼',
    '냉장실 문칸 2층 왼',
    '냉장실 문칸 3층 왼',
    '냉장실 문칸 4층 왼',
    '냉장실 문칸 1층 오',
    '냉장실 문칸 2층 오',
    '냉장실 문칸 3층 오',
    '냉장실 문칸 4층 오',
  ],
  '신규 냉장고': [
    '냉장실 1층 왼',
    '냉장실 2층 왼',
    '냉장실 1층 오',
    '냉장실 2층 오',
    '냉동실 1층',
    '냉동실 2층',
    '문칸 상단 왼',
    '문칸 상단 오',
    '문칸 하단 왼',
    '문칸 하단 오',
  ],
};

/// 간단한 범위 클래스
class CompRange {
  final int start;
  final int end;
  CompRange(this.start, this.end);
  int get count => end - start + 1;
  bool contains(int v) => v >= start && v <= end;
  int indexOf(int v) => v - start;
}

/// 냉장고 안의 식재료나 물건 하나를 표현하는 모델 클래스입니다.
class FridgeItem {
  final String user_id;
  final int ingredient_id;
  final String imageUrl;
  final int fridge_id;
  int area_id;
  final String alias;
  final int quantity;
  final String purchase_date;
  final String expiration_date;
  final String memo;

  FridgeItem({
    required this.user_id,
    required this.imageUrl,
    required this.ingredient_id,
    required this.fridge_id,
    required this.area_id,
    required this.alias,
    required this.quantity,
    required this.expiration_date,
    required this.purchase_date,
    required this.memo,
  });

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
      purchase_date: json['purchase_date'],
      memo: json['note'] ?? '',
    );
  }

  FridgeItem copyWith({
    String? user_id,
    String? imageUrl,
    int? ingredient_id,
    int? fridge_id,
    int? area_id,
    String? alias,
    int? quantity,
    String? expiration_date,
    String? purchase_date,
    String? memo,
  }) {
    return FridgeItem(
      user_id: user_id ?? this.user_id,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredient_id: ingredient_id ?? this.ingredient_id,
      fridge_id: fridge_id ?? this.fridge_id,
      area_id: area_id ?? this.area_id,
      alias: alias ?? this.alias,
      quantity: quantity ?? this.quantity,
      expiration_date: expiration_date ?? this.expiration_date,
      purchase_date: purchase_date ?? this.purchase_date,
      memo: memo ?? this.memo,
    );
  }
}

const Map<int, String> fridgeIdToName = {
  0: 'SAMSUNG BESPOKE 냉장고 2도어 키친핏 333L',
  1: 'LG 모던엣지 냉장고 462L',
  2: '신규 냉장고',
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
    _itemsFuture = _fetchItemsFromServer(fridge: _selectedFridge);
    setState(() {});
  }

  Future<List<FridgeItem>> _fetchItemsFromServer({
    required String fridge,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/ingredients?user_id=${widget.userId}',
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
      '${ApiConfig.baseUrl}/ingredients/$id',
    );
    final response = await http.delete(uri);
    if (response.statusCode == 200) {
      _loadItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${response.statusCode}')),
      );
    }
  }

  Widget _buildImage(String imageUrl,
      {double width = 100, double height = 100}) {
    const baseUrl = '${ApiConfig.baseUrl}';
    final fullUrl =
        imageUrl.startsWith('http') ? imageUrl : '$baseUrl$imageUrl';

    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Map<String, CompRange> _computeCompartmentRanges(String fridgeName) {
    final layout = fridgeLayouts[fridgeName];
    final ranges = <String, CompRange>{};
    if (layout == null) return ranges;
    int start = 1;
    layout.forEach((compartment, cfg) {
      final int count = cfg.rows * cfg.cols;
      final end = start + count - 1;
      ranges[compartment] = CompRange(start, end);
      start = end + 1;
    });
    return ranges;
  }

  Future<void> _handleDrop(FridgeItem draggedItem, int newAreaId) async {
    final oldArea = draggedItem.area_id;
    setState(() {
      draggedItem.area_id = newAreaId;
    });

    final data = {
      "user_id": draggedItem.user_id,
      "ingredient_name": draggedItem.alias,
      "quantity": draggedItem.quantity,
      "purchase_date": draggedItem.purchase_date,
      "expiration_date": draggedItem.expiration_date,
      "alias": draggedItem.alias,
      "area_id": newAreaId,
      "image": draggedItem.imageUrl,
      "note": draggedItem.memo,
      "fridge_id": draggedItem.fridge_id,
    };

    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/ingredients/${draggedItem.ingredient_id}');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이동 저장 완료')));
      _loadItems();
    } else {
      setState(() {
        draggedItem.area_id = oldArea;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이동 저장 실패: ${res.statusCode} ${res.body}')),
      );
    }
  }

  Widget _buildPartitionWithItems(List<FridgeItem> items) {
    final compartmentName =
        _compartments.isNotEmpty ? _compartments[_currentCompartment] : '';
    if (compartmentName.isEmpty) return const SizedBox.shrink();

    final config = fridgeLayouts[_selectedFridge]?[compartmentName];
    if (config == null) return const SizedBox.shrink();

    const spacing = 12.0;
    const borderWidth = 3.0;

    final fridgeId = fridgeIdToName.entries
        .firstWhere((e) => e.value == _selectedFridge)
        .key;

    final ranges = _computeCompartmentRanges(_selectedFridge);
    final compRange = ranges[compartmentName];
    if (compRange == null) return const SizedBox.shrink();

    final int cellCount = config.rows * config.cols;

    final cells = List<List<FridgeItem>>.generate(cellCount, (_) => []);
    for (final item in items) {
      if (item.fridge_id == fridgeId && compRange.contains(item.area_id)) {
        final idx = compRange.indexOf(item.area_id);
        if (idx >= 0 && idx < cellCount) {
          cells[idx].add(item);
        }
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
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
        itemCount: cellCount,
        itemBuilder: (context, idx) {
          final cellItems = cells[idx];

          return DragTarget<FridgeItem>(
            onWillAccept: (data) => true,
            onAccept: (draggedItem) {
              final newAreaId = compRange.start + idx;
              _handleDrop(draggedItem, newAreaId);
            },
            builder: (context, candidateData, rejectedData) {
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
                child: cellItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_box_outlined,
                                size: 28, color: Colors.grey.shade500),
                            const SizedBox(height: 4),
                            Text(
                              '빈칸\n(area ${compRange.start + idx})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: cellItems.map((item) {
                          return GestureDetector(
                            onTap: () => _showItemDetailDialog(item),
                            child: Draggable<FridgeItem>(
                              data: item,
                              feedback: Material(
                                color: Colors.transparent,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _buildImage(item.imageUrl,
                                      width: 50, height: 50),
                                ),
                              ),
                              childWhenDragging: Container(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _buildImage(item.imageUrl,
                                    width: 50, height: 50),
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
    });
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
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '냉장고 종류',
                border: OutlineInputBorder(),
              ),
              items: _fridges
                  .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                          f,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
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

  void _showItemDetailDialog(FridgeItem item) {
    final aliasCtrl =
        TextEditingController(text: utf8.decode(item.alias.codeUnits));
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final boughtCtrl =
        TextEditingController(text: utf8.decode(item.purchase_date.codeUnits));
    final expireCtrl = TextEditingController(
        text: utf8.decode(item.expiration_date.codeUnits));
    final memoCtrl =
        TextEditingController(text: utf8.decode(item.memo.codeUnits));

    // 현재 냉장고의 구획 이름 목록
    final compartmentNames = fridgeLayoutsNames[_selectedFridge] ?? [];
    // 현재 area_id에 맞는 index 선택
    int currentIndex = item.area_id - 1;

    int selectedIndex = currentIndex;

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
              const SizedBox(height: 12),
              // 위치 변경용 Dropdown
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: '위치 변경',
                  border: OutlineInputBorder(),
                ),
                value: selectedIndex,
                items: List.generate(compartmentNames.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(compartmentNames[index]),
                  );
                }),
                onChanged: (v) {
                  if (v != null) selectedIndex = v;
                },
              ),
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
              // area_id는 선택된 index + 1
              final newAreaId = selectedIndex + 1;

              final data = {
                "user_id": item.user_id,
                "ingredient_name": aliasCtrl.text,
                "quantity": int.parse(qtyCtrl.text),
                "purchase_date": boughtCtrl.text,
                "expiration_date": expireCtrl.text,
                "alias": aliasCtrl.text,
                "area_id": newAreaId,
                "image": item.imageUrl,
                "note": memoCtrl.text,
                "fridge_id": item.fridge_id,
              };

              final uri = Uri.parse(
                  '${ApiConfig.baseUrl}/ingredients/${item.ingredient_id}');
              final res = await http.put(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: json.encode(data),
              );

              if (res.statusCode == 200) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('수정 성공!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('수정 실패 ${res.statusCode} ${res.body}')));
              }

              Navigator.of(context).pop();
              _loadItems();
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }
}
