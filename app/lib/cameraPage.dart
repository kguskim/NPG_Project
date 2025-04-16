import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller; // 카메라 컨트롤러
  late Future<void> _initializeControllerFuture =
      _initializeControllerFuture; // 카메라 초기화 대기용 Future

  @override
  void initState() {
    _initializeCamera();
    super.initState();
  }

  // 카메라 초기화 함수
  Future<void> _initializeCamera() async {
    // 사용 가능한 카메라 목록 가져오기
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    // 카메라 컨트롤러 생성
    _controller = CameraController(firstCamera, ResolutionPreset.high);

    // 카메라 초기화
    _initializeControllerFuture = _controller.initialize();

    setState(() {});
  }

  @override
  void dispose() {
    // 페이지가 사라질 때 카메라 컨트롤러 자원 해제
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture, // 카메라 초기화 기다리기
        builder: (context, snapshot) {
          // 초기화가 완료되면 카메라 미리보기 표시
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller); // 카메라 미리보기
          } else {
            return const Center(child: CircularProgressIndicator()); // 로딩 중 표시
          }
        },
      ),
      // 버튼 누를 시 카메라 화면의 캡쳐본을 보여주는 화면으로 이동
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            // 현재 카메라 화면 캡쳐
            final image = await _controller.takePicture();

            if (!mounted) return;

            // 사진 보여주기
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => DisplayPictureScreen(imagePath: image.path),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --------------------------------
// 찍은 사진 보여주는 위젯
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캡쳐 화면')),
      body: Image.file(File(imagePath)),
    );
  }
}
