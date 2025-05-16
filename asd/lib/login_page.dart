import 'package:flutter/material.dart';
import 'home.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController controller = TextEditingController();
  final TextEditingController controller2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 키보드 내리기
        },
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
                Form(
                  child: Theme(
                    data: ThemeData(
                      primaryColor: Colors.grey,
                      inputDecorationTheme: const InputDecorationTheme(
                        labelStyle:
                            TextStyle(color: Colors.teal, fontSize: 15.0),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Builder(
                        builder: (context) {
                          return Column(
                            children: [
                              TextField(
                                controller: controller,
                                autofocus: true,
                                decoration:
                                    const InputDecoration(labelText: 'ID'),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              TextField(
                                controller: controller2,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                keyboardType: TextInputType.text,
                                obscureText: true,
                              ),
                              const SizedBox(height: 40.0),

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
                                onPressed: () {
                                  if (controller.text == 'test@email.com' &&
                                      controller2.text == '1234') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            HomePage(),
                                      ),
                                    );
                                  } else if (controller.text ==
                                          'test@email.com' &&
                                      controller2.text != '1234') {
                                    showSnackBar(
                                        context, const Text('잘못된 비밀번호입니다.'));
                                  } else if (controller.text !=
                                          'test@email.com' &&
                                      controller2.text == '1234') {
                                    showSnackBar(
                                        context, const Text('아이디를 확인해 주세요.'));
                                  } else {
                                    showSnackBar(context,
                                        const Text('아이디와 비밀번호를 확인해 주세요.'));
                                  }
                                },
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
                          );
                        },
                      ),
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
