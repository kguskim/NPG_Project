import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  TextEditingController controller = TextEditingController();
  TextEditingController controller2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // email, password 입력하는 부분을 제외한 화면을 탭하면, 키보드 사라지게 GestureDetector 사용
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(padding: EdgeInsets.only(top: 300)),
              Form(
                child: Theme(
                  data: ThemeData(
                    primaryColor: Colors.grey,
                    inputDecorationTheme: InputDecorationTheme(
                      labelStyle: TextStyle(color: Colors.teal, fontSize: 15.0),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(40.0),
                    child: Builder(
                      builder: (context) {
                        return Column(
                          children: [
                            TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: InputDecoration(labelText: 'ID'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            TextField(
                              controller: controller2,
                              decoration: InputDecoration(
                                labelText: 'Password',
                              ),
                              keyboardType: TextInputType.text,
                              obscureText: true, // 비밀번호 안보이도록 하는 것
                            ),
                            SizedBox(height: 40.0),
                            // 회원가입 버튼
                            TextButton(onPressed: () {}, child: Text("회원가입")),
                            ButtonTheme(
                              minWidth: 100.0,
                              height: 50.0,
                              child: ElevatedButton(
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
                                      context,
                                      Text('Wrong password'),
                                    );
                                    showSnackBar(context, Text('잘못된 비밀번호입니다.'));
                                  } else if (controller.text !=
                                          'test@email.com' &&
                                      controller2.text == '1234') {
                                    showSnackBar(context, Text('Wrong email'));
                                    showSnackBar(
                                      context,
                                      Text('아이디를 확인해 주세요.'),
                                    );
                                  } else {
                                    showSnackBar(
                                      context,
                                      Text('아이디와 비밀번호를 확인해 주세요.'),
                                    );
                                  }
                                },
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 35.0,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                ),
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
    );
  }
}

void showSnackBar(BuildContext context, Text text) {
  final snackBar = SnackBar(content: text, backgroundColor: Colors.red);

  // Find the ScaffoldMessenger in the widget tree
  // and use it to show a SnackBar.
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
