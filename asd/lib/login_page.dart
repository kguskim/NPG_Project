import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();

  Future<void> login(BuildContext context) async {
    final id = controller.text;
    final password = controller2.text;

    try {
      final url = Uri.parse(
          'https://3d57-121-188-29-7.ngrok-free.app/users/login'); // 실제 주소로 바꿔주세요
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': id, 'password': password}),
      );
      if (response.statusCode == 200 && response.body == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (BuildContext context) => HomePage()),
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
                        const SizedBox(height: 40.0),
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
