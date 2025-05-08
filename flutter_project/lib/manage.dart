// lib/manage_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  // 드롭다운: 냉장고 종류
  final List<String> _fridges = ['SAMSUNG BEOKE 냉장고 2도어 키친핏 333L', '사무실 냉장고', '친구 냉장고'];
  String _selectedFridge = 'SAMSUNG BEOKE 냉장고 2도어 키친핏 333L';

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Text(
                  _compartments[_currentCompartment],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

            // 아이템 그리드 (카메라 기능 제거)
            Expanded(
              child: FutureBuilder<List<FridgeItem>>(
                future: _itemsFuture,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snap.data ?? [];
                  return GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                child: Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
