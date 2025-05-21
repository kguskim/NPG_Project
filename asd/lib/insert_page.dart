import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:yolo/home.dart';
import 'manage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InsertPage extends StatefulWidget {
  final String userId;
  final String data;
  final String imagePath;

  const InsertPage(
      {Key? key,
      required this.userId,
      required this.data,
      required this.imagePath})
      : super(key: key);

  @override
  InsertPageState createState() => InsertPageState();
}

class InsertPageState extends State<InsertPage> {
  static String txt = '';

  final List<String> categories = [
    '감자류',
    '견과종실류',
    '곡류',
    '과일류',
    '난류',
    '당류',
    '두류',
    '버섯류',
    '어패류',
    '유제품',
    '유지류',
    '육류',
    '음료류',
    '조리가공식품류',
    '조미료류',
    '주류',
    '차류',
    '채소류',
    '해조류',
    '기타'
  ];
  late String selectedFridgeFromManage;
  late String selectedLocation;
  List<String> get locations =>
      fridgeLayouts[selectedFridgeFromManage]?.keys.toList() ?? [];
  @override
  void initState() {
    super.initState();
    _loadLastFridge();
  }

  Future<void> _loadLastFridge() async {
    final prefs = await SharedPreferences.getInstance();
    final fridgeName =
        prefs.getString('last_selected_fridge') ?? fridgeLayouts.keys.first;
    setState(() {
      selectedFridgeFromManage = fridgeName;
      selectedLocation = locations.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    String selectedCategory = categories[0];
    String selectedLocation = locations[0];
    DateTime purchaseDate = DateTime(2025, 1, 1);
    DateTime expiryDate = DateTime(2025, 12, 31);

    final TextEditingController nameController =
        TextEditingController(text: widget.data);
    final TextEditingController quantityController =
        TextEditingController(text: '1');
    final TextEditingController typeController =
        TextEditingController(text: '바나나');
    final TextEditingController memoController = TextEditingController();

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

            ElevatedButton(
              onPressed: () async {
                int fridge_id = 0;
                for (int i = 0; i < fridges.length; i++) {
                  if (fridges[i] == selectedFridgeFromManage) {
                    fridge_id = i;
                    break;
                  }
                }

                int area_id = 0;
                for (int i = 0; i < locations.length; i++) {
                  if (locations[i] == selectedLocation) {
                    area_id = i;
                    break;
                  }
                }

                // 전송할 데이터 준비
                final data = {
                  "user_id": widget.userId,
                  "ingredient_name": typeController.text, // 분류한 식재료명 (예: 삼다수)
                  "quantity": int.parse(quantityController.text),
                  "purchase_date": purchaseDate.year.toString() +
                      "-" +
                      purchaseDate.month.toString().padLeft(2, '0') +
                      "-" +
                      purchaseDate.day.toString().padLeft(2, '0'),
                  "expiration_date": expiryDate.year.toString() +
                      "-" +
                      expiryDate.month.toString().padLeft(2, '0') +
                      "-" +
                      expiryDate.day.toString().padLeft(2, '0'),
                  "alias": nameController.text, // 식재료명 (예: 생수, 바나나)
                  "area_id": area_id + 1,
                  "image": uploadImage(File(widget.imagePath)).toString(),
                  "note": memoController.text,
                  "fridge_id": fridge_id,
                };

                registerIngredient(data, widget.imagePath);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
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
              MaterialPageRoute(
                  builder: (_) => (HomePage(userId: widget.userId))),
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

Future<String?> uploadImage(File imageFile) async {
  final uri =
      Uri.parse("https://baa8-121-188-29-7.ngrok-free.app/upload-image");
  final request = http.MultipartRequest('POST', uri);
  final imageStream = http.ByteStream(imageFile.openRead());
  final imageLength = await imageFile.length();

  final multipartFile = http.MultipartFile(
    'file',
    imageStream,
    imageLength,
    filename: imageFile.path.split("/").last,
  );

  request.files.add(multipartFile);
  final response = await request.send();

  if (response.statusCode == 200) {
    final resStr = await response.stream.bytesToString();
    final jsonData = jsonDecode(resStr);
    return jsonData['image_url']; // /static/images/abc.jpg
  } else {
    return null;
  }
}

Future<void> registerIngredient(Map data, String imageUrl) async {
  final uri = Uri.parse("https://baa8-121-188-29-7.ngrok-free.app/ingredients");

  final body = data;

  final response = await http.post(
    uri,
    headers: {"Content-Type": "application/json"},
    body: json.encode(body),
  );

  if (response.statusCode == 200) {
    print("등록 성공");
  } else {
    print("등록 실패: ${response.body}");
  }
}
