import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home.dart';
import 'register_page.dart';
import 'package:yolo/config/constants.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();

  Future<void> login(BuildContext context) async {
    final id = controller.text;
    final password = controller2.text;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': id, 'password': password}),
      );
      showSnackBar(context, Text("환영합니다 " + id + "님"));

      if (response.statusCode == 200 && response.body == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => HomePage(userId: id)),
        );
      } else {
        showSnackBar(context, const Text('아이디와 비밀번호를 확인해 주세요.'));
      }
    } catch (e) {
      showSnackBar(context, const Text('서버에 연결할 수 없습니다.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "NPG",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
                ),
                const SizedBox(height: 40),
                Theme(
                  data: ThemeData(
                    primaryColor: Colors.grey,
                    inputDecorationTheme: const InputDecorationTheme(
                      labelStyle: TextStyle(color: Colors.teal, fontSize: 15.0),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(labelText: 'ID'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        TextField(
                          controller: controller2,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 15.0),

                        // 아이디/비밀번호 찾기 버튼 추가
                        TextButton(
                          onPressed: () {
                            // 아이디/비밀번호 찾기 페이지로 이동
                            // 여기에 아이디/비밀번호 찾기 페이지 구현 필요
                          },
                          child: const Text(
                            "아이디/비밀번호 찾기",
                          ),
                        ),

                        // 회원가입 버튼
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    RegisterPage(),
                              ),
                            );
                          },
                          child: const Text("회원가입"),
                        ),

                        const SizedBox(height: 5.0),

                        // 로그인 버튼
                        ElevatedButton(
                          onPressed: () => login(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 25.0, vertical: 8.0),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 35.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 스낵바 출력 함수
void showSnackBar(BuildContext context, Text text) {
  final snackBar = SnackBar(content: text, backgroundColor: Colors.red);
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
