import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yolo/home.dart';

class InsertPage extends StatefulWidget {
  final String data;
  final String imagePath;

  const InsertPage({Key? key, required this.data, required this.imagePath})
      : super(key: key);

  @override
  InsertPageState createState() => InsertPageState();
}

class InsertPageState extends State<InsertPage> {
  static String txt = '';

  final TextEditingController quantityController =
      TextEditingController(text: '1');
  final TextEditingController typeController =
      TextEditingController(text: '바나나');
  final TextEditingController memoController = TextEditingController();

  final List<String> categories = ['과일', '야채', '육류'];
  final List<String> locations = [
    '냉장 1층',
    '냉장 2층',
    '냉장 3층',
    '냉장 4층',
    '냉장 5층',
    '냉동실'
  ];

  @override
  Widget build(BuildContext context) {
    String selectedCategory = categories[0];
    String selectedLocation = locations[0];
    DateTime purchaseDate = DateTime(2025, 1, 1);
    DateTime expiryDate = DateTime(2025, 12, 31);

    final TextEditingController nameController =
        TextEditingController(text: '${widget.data}');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Align(
            alignment: Alignment(-0.255, 0.5),
            child: Text('식재료 등록',
                style: TextStyle(color: Colors.lightBlue.shade700))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 이미지 파일
            const SizedBox(height: 16),
            Image.file((File('${widget.imagePath}'))),

            // 식재료명, 수량, 분류
            Row(
              children: [
                Expanded(child: _buildLabeledTextField('식재료명', nameController)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildLabeledTextField('수량', quantityController)),
              ],
            ),
            const SizedBox(height: 10),
            _buildLabeledTextField('분류', nameController),
            const SizedBox(height: 10),

            // 카테고리 & 배치영역 드롭다운
            Row(
              children: [
                Expanded(
                    child: _buildDropdownField(
                        '카테고리', categories, selectedCategory)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildDropdownField(
                        '배치영역', locations, selectedLocation)),
              ],
            ),
            const SizedBox(height: 10),

            // 날짜 선택
            Row(
              children: [
                Expanded(child: _buildDateField(context, '구매일자', purchaseDate)),
                const SizedBox(width: 10),
                Expanded(child: _buildDateField(context, '소비일자', expiryDate)),
              ],
            ),
            const SizedBox(height: 10),

            // 메모 필드
            Text('메모',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(
              controller: memoController,
              decoration: InputDecoration(
                hintText: 'Placeholder',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // 저장 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text('등록', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => (const HomePage())),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabeledTextField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      String label, List<String> items, String selectedItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: selectedItem,
          onChanged: (value) {},
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          decoration: InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          initialValue:
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          decoration: InputDecoration(border: OutlineInputBorder()),
          onTap: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
          },
        ),
      ],
    );
  }
}
