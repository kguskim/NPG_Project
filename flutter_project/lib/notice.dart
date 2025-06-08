import 'package:flutter/material.dart';

/// 공지사항 데이터 모델
class Notice {
  final int id;
  final String title;
  final DateTime createdAt;

  Notice({
    required this.id,
    required this.title,
    required this.createdAt,
  });
}

/// 공지사항 위젯
class NoticeBoard extends StatefulWidget {
  const NoticeBoard({super.key});

  @override
  State<NoticeBoard> createState() => _NoticeBoardState();
}

class _NoticeBoardState extends State<NoticeBoard> {
  late Future<List<Notice>> _noticesFuture;

  @override
  void initState() {
    super.initState();
    _noticesFuture = fetchNotices(); // 나중에 서버 연동으로 교체
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공지사항',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Notice>>(
          future: _noticesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('공지 로드 실패');
            }

            final notices = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notices.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                return Text('• ${notices[index].title}');
              },
            );
          },
        ),
      ],
    );
  }

  /// 테스트용 공지 데이터 (서버 연결 시 교체)
  Future<List<Notice>> fetchNotices() async {
    await Future.delayed(const Duration(seconds: 1)); // 로딩 시뮬레이션
    return [
      Notice(id: 1, title: '앱 업데이트 안내', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
      Notice(id: 2, title: '정기 점검 예정', createdAt: DateTime.now().subtract(const Duration(days: 1))),
      Notice(id: 3, title: '신규 기능 추가', createdAt: DateTime.now().subtract(const Duration(days: 2))),
      Notice(id: 4, title: '이벤트 참여 안내', createdAt: DateTime.now().subtract(const Duration(days: 3))),
    ];
  }
}
