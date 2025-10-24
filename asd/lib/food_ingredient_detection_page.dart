import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:yolo/insert_page.dart';

late List<CameraDescription> cameras;

class App extends StatelessWidget {
  final String userId;
  const App({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'MegaView',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        // home: const MainScreen(),
        home: YoloVideo(userId: userId));
  }
}

// YOLO V5 REAL-TIME OBJECT DETECTION

class YoloVideo extends StatefulWidget {
  final String userId;
  const YoloVideo({super.key, required this.userId});

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> with WidgetsBindingObserver {
  late CameraController controller;
  late FlutterVision vision;
  bool isLoaded = false;
  bool isDetecting = false;
  List<Map<String, dynamic>> yoloResults = [];
  CameraImage? cameraImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    vision = FlutterVision();
    init();
  }

  Future<void> init() async {
    final cameras = await availableCameras();

    controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    await loadYoloModel();

    setState(() {
      isLoaded = true;
    });

    await startDetection();
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await stopDetection();
    await controller.dispose();
    await vision.closeYoloModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text("Model not loaded. Waiting for it.",
              style: TextStyle(color: Colors.white)),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(
            controller,
          ),
        ),
        ...displayBoxesAroundRecognizedObjects(size),
        Positioned(
          bottom: 75,
          width: MediaQuery.of(context).size.width,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  width: 5, color: Colors.white, style: BorderStyle.solid),
            ),
            child: IconButton(
              onPressed: () async {
                final XFile imageFile = await controller.takePicture();

                String topTag = "Unknown";
                try {
                  if (yoloResults.isNotEmpty) {
                    final best = yoloResults.reduce((a, b) =>
                        ((a["box"][4] ?? 0) > (b["box"][4] ?? 0)) ? a : b);
                    topTag = best["tag"] as String? ?? "Unknown";
                  }
                } catch (_) {
                  topTag = "Unknown";
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InsertPage(
                      userId: widget.userId,
                      data: topTag,
                      imagePath: imageFile.path,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
              iconSize: 50,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/yolov5n.tflite',
      modelVersion: "yolov5",
      numThreads: 4,
      useGpu: true,
    );
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  // 객체 인식 시작
  Future<void> startDetection() async {
    if (!controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }

    setState(() {
      isDetecting = true;
    });

    await controller.startImageStream((image) async {
      if (!isDetecting) return;
      cameraImage = image;
      final results = await vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5,
      );

      if (mounted && results.isNotEmpty) {
        setState(() {
          yoloResults = results;
        });
      }
    });
  }

  Future<void> stopDetection() async {
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    // 1️⃣ 가장 높은 정확도의 결과 하나만 추출
    final topResult = yoloResults.reduce((a, b) {
      // YOLO 플러그인에서는 box[4]가 confidence임
      final confA = (a["box"][4] ?? 0).toDouble();
      final confB = (b["box"][4] ?? 0).toDouble();
      return confA > confB ? a : b;
    });

    // 2️⃣ 화면 비율 계산
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    // 3️⃣ 박스 색상
    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    // 4️⃣ 해당 객체만 표시
    return [
      Positioned(
        left: topResult["box"][0] * factorX,
        top: topResult["box"][1] * factorY,
        width: (topResult["box"][2] - topResult["box"][0]) * factorX,
        height: (topResult["box"][3] - topResult["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${topResult['tag']} ${(topResult['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      ),
    ];
  }

  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      // 다시 들어왔을 때 YOLO 재시작
      if (!controller.value.isInitialized) {
        await controller.initialize();
      }
      if (!controller.value.isStreamingImages) {
        await startDetection();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      await stopDetection();
    }
  }
}
