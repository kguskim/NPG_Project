// lib/insert_page.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yolo/home.dart';
import 'package:yolo/manage.dart';  // fridgeLayouts 사용
import 'package:http/http.dart' as http;

class InsertPage extends StatefulWidget {
  final String userId;
  final String data;      // OCR로 인식된 이름
  final String imagePath; // 카메라 촬영된 파일 경로

  const InsertPage({
    Key? key,
    required this.userId,
    required this.data,
    required this.imagePath,
  }) : super(key: key);

  @override
  InsertPageState createState() => InsertPageState();
}

class InsertPageState extends State<InsertPage> {
  // --- State 필드 선언 ---

  // 드롭다운 카테고리 목록
  final List<String> categories = [
    '감자류','견과종실류','곡류','과일류','난류','당류','두류','버섯류','어패류',
    '유제품','유지류','육류','음료류','조리가공식품류','조미료류','주류','차류',
    '채소류','해조류','기타',
  ];

  late String _selectedCategory;
  late String _selectedLocation;

  DateTime _purchaseDate = DateTime.now();
  DateTime _expiryDate   = DateTime.now();

  // 텍스트 컨트롤러
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _typeController;    // 분류된 이름
  late TextEditingController _memoController;

  late String _selectedFridgeName;

  @override
  void initState() {
    super.initState();
    // 컨트롤러 초기화
    _nameController     = TextEditingController(text: widget.data);
    _quantityController = TextEditingController(text: '1');
    _typeController     = TextEditingController(text: widget.data);
    _memoController     = TextEditingController();

    _selectedCategory = categories.first;

    _loadLastFridge();
  }

  Future<void> _loadLastFridge() async {
    final prefs = await SharedPreferences.getInstance();
    // private 상수 대신 문자열 리터럴 사용
    final fridgeName = prefs.getString('last_selected_fridge')
      ?? fridgeLayouts.keys.first;
    setState(() {
      _selectedFridgeName = fridgeName;
      final locs = fridgeLayouts[_selectedFridgeName]!.keys.toList();
      _selectedLocation = locs.first;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _typeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = fridgeLayouts[_selectedFridgeName]!.keys.toList();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('식재료 등록', style: TextStyle(color: Colors.lightBlue)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 1) 촬영된 이미지
            Image.file(File(widget.imagePath)),
            const SizedBox(height: 16),

            // 2) 이름 / 수량
            Row(
              children: [
                Expanded(child: _buildLabeledField('식재료명', _nameController)),
                const SizedBox(width: 10),
                Expanded(child: _buildLabeledField('수량', _quantityController, isNumber: true)),
              ],
            ),
            const SizedBox(height: 10),

            // 3) 분류 (OCR 결과 기본값)
            _buildLabeledField('분류', _typeController),
            const SizedBox(height: 10),

            // 4) 카테고리 & 배치영역 드롭다운
            Row(
              children: [
                Expanded(child: _buildDropdown('카테고리', categories, _selectedCategory, (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                })),
                const SizedBox(width: 10),
                Expanded(child: _buildDropdown('배치영역', locations, _selectedLocation, (v) {
                  if (v != null) setState(() => _selectedLocation = v);
                })),
              ],
            ),
            const SizedBox(height: 10),

            // 5) 날짜 선택
            Row(
              children: [
                Expanded(child: _buildDateField(context, '구매일자', _purchaseDate, (d) {
                  setState(() => _purchaseDate = d);
                })),
                const SizedBox(width: 10),
                Expanded(child: _buildDateField(context, '소비일자', _expiryDate, (d) {
                  setState(() => _expiryDate = d);
                })),
              ],
            ),
            const SizedBox(height: 10),

            // 6) 메모
            const Text('메모', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: _memoController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '메모를 입력하세요',
              ),
            ),
            const SizedBox(height: 20),

            // 7) 등록 버튼
            ElevatedButton(
              onPressed: _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('등록', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(userId: widget.userId)),
            );
          },
        ),
      ),
    );
  }

  /// 라벨 + 텍스트필드
  Widget _buildLabeledField(String label, TextEditingController ctrl, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  /// 라벨 + 드롭다운
  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  /// 라벨 + 날짜 선택 필드
  Widget _buildDateField(
    BuildContext ctx,
    String label,
    DateTime date,
    ValueChanged<DateTime> onDatePicked,
  ) {
    final text = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          initialValue: text,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onTap: () async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) onDatePicked(picked);
          },
        ),
      ],
    );
  }

  /// 등록 처리
  Future<void> _onSubmit() async {
    // fridge_id, area_id 계산
    final fridgeId = fridges.indexOf(_selectedFridgeName);
    final locations = fridgeLayouts[_selectedFridgeName]!.keys.toList();
    final areaId   = locations.indexOf(_selectedLocation) + 1;

    final imageUrl = await _uploadImage(File(widget.imagePath));
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지 업로드 실패')));
      return;
    }

    final data = {
      "user_id": widget.userId,
      "ingredient_name": _typeController.text, // 분류된 이름
      "quantity": int.parse(_quantityController.text),
      "purchase_date": textDate(_purchaseDate),
      "expiration_date": textDate(_expiryDate),
      "alias": _nameController.text, // 실제 이름
      "area_id": areaId,
      "image": imageUrl,
      "note": _memoController.text,
      "fridge_id": fridgeId,
    };

    final uri = Uri.parse("https://a4a5-121-188-29-7.ngrok-free.app/ingredients");
    final resp = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );
    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록 성공')));
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 실패: ${resp.body}')));
    }
  }

  Future<String?> _uploadImage(File file) async {
    final uri = Uri.parse("https://a4a5-121-188-29-7.ngrok-free.app/upload-image");
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await req.send();
    if (res.statusCode == 200) {
      final js = jsonDecode(await res.stream.bytesToString());
      return js['image_url'];
    }
    return null;
  }

  String textDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
