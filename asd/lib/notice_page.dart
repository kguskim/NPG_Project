import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공지사항 게시판',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NoticeBoard(noticeId: 1), // 외부에서 ID 전달
    );
  }
}

class NoticeBoard extends StatefulWidget {
  final int noticeId;

  const NoticeBoard({super.key, required this.noticeId});

  @override
  State<NoticeBoard> createState() => _NoticeBoardState();
}

class _NoticeBoardState extends State<NoticeBoard> {
  late int noticeId;
  Map<String, dynamic>? notice;
  bool isLoading = true;
  bool isError = false;

  final dummyNotices = {
    1: {
      'title': '더미 공지사항 1',
      'author': '관리자',
      'content': '서버 연결 실패로 인해 표시되는 공지사항입니다.'
    },
    2: {
      'title': '더미 공지사항 2',
      'author': '운영팀',
      'content': '네트워크 오류로 인한 임시 공지입니다.'
    },
    3: {'title': '더미 공지사항 3', 'author': '시스템', 'content': '서버 응답을 받지 못했습니다.'},
    4: {'title': '더미 공지사항 4', 'author': '관리자', 'content': '이 공지사항은 로컬 데이터입니다.'},
  };

  @override
  void initState() {
    super.initState();
    noticeId = widget.noticeId;
    fetchNotice(noticeId);
  }

  Future<void> fetchNotice(int id) async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://a4a5-121-188-29-7.ngrok-free.app/notices/$id'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          notice = data;
          isLoading = false;
        });
      } else {
        throw Exception('서버 오류');
      }
    } catch (e) {
      setState(() {
        notice = dummyNotices[id];
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('공지사항'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notice == null
              ? const Center(child: Text('공지사항을 불러올 수 없습니다.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice!['title'] ?? '',
                      ),
                      const SizedBox(height: 8),
                      const Divider(), // 🔹 제목과 작성자 사이 구분선
                      const SizedBox(height: 8),
                      Text(
                        '작성자: ${notice!['author'] ?? '알 수 없음'}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: MediaQuery.of(context).size.height *
                            0.7, // 원하는 고정 높이 설정
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            child: Text(
                              notice!['content'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),

                      if (isError)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            '※ 서버 연결에 실패하여 더미 데이터를 표시합니다.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
