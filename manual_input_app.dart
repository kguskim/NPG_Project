// lib/ingredient_input.dart

import 'package:flutter/material.dart';

class IngredientInputScreen extends StatefulWidget {
  @override
    _IngredientInputScreenState createStare() => _IngredientInputScreenState();
}

class _IngredientInputScreenState extends State<IngredientInputScreen> {
  final _formKey = GlobalKey<FormState>();

  String ingredientName = '';
  String category = '';
  DateTime? expirationDate;
  String quantity = '';
  String location = '';
  String imageUrl = '';

  final List<String> categoried = [
    '채소', '과일', '육류', '해산물', '유제품', '곡류', '기타'
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicke(
      context: context,
      initialDate: expirationDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked !=null && picked != expirationDate) {
      setState(() {
        expirationDate = picked;
      });
    }
  }
}

void _submitForm() {
  if (_formKey.currentState!.validate() && expirationDate != null) {
    _formKey.currentState!.save();

    final ingredientDate = {
      'ingredientName': ingredientName,
      'category': category,
      'expirationDate': expirationDate!.toIso8601String(),
      'quantity': quantity,
      'location': location,
      'imageUrl': imageUrl,
    }:

    print('입력된 식재료 데이터: $ingredientData');

    ScaffoldMessenger.of(context).showSnackbar(
      showSnackbar(content: Text('식재료가 입력되었습니다!')),
    );

    // 폼 초기화
    _formKey.currentState!.reset();
    setState(() {
      expirationDate = null;
      category = '';
    });
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('식재료 수동 입력'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            //식재료 이름 입력
            TextFormField(
              decoration: InputDecoration(labelText: '식재료 이름'),
              validator: (value) =>
                value == null || value.isEmpty ? '식재료 이름을 입력하세요' : null,
              onSaved: (value) => ingredientName = value!.trim(),
            ),
            //카테고리 들롭다운
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: '카테고리'),
              value: category.isNotEmpty ? category : null,
              items: categories
                .map((cat) => DropdownMenuItem(
                   value: cat,
                    child: Text(cat),
                  ))
                .toList(),
              onChanged: (value) {
                setState(() {
                  category = value ?? '';
                });
              },
              validator: (value) =>
                value == null || value.isEmpty ? '카테고리를 선택하세요' : null,
            ),
            //유통기한 선택
            ListTitle(
              contentPadding: EdgeInsets.zero,
              title: Text('유통기한'),
              subtitle: Text(expirationDate == null
                ? '날짜 선택'
                : '$(expirationDate!.year}-${expirationDate!.month.toString().padLeft(2, '0'))-${expirationDate!.day.toString().padLeft(2, '0')}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            )'
            //수량 입력
            TextFormField(
              decoration: InputDecoration(
                labelText: '수량',
                hintText: '예: 500g 또는 2개',
              ),
              validator: (value) => quantity = value!.trim(),
            ),
            //보관 위치 입력
            TextFormField(
              decoration: InputDecoration(
                labelText: '보관 위치',
                hintText: '예: 냉장실, 냉동실, 야채칸',
              ),
              validator: (value) =>
                value == null || value.isEmpty ? '보관 위치를 입력하세요' : null,
              onSaved: (value) => location = value!.trim(),
            ),
              )
            )
          ]
        )
      )
    )
  )
}
