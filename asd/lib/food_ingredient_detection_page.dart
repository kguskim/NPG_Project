import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:yolo/insert_page.dart';

late List<CameraDescription> cameras;

class App extends StatelessWidget {
  const App({super.key});

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
        home: const YoloVideo());
  }
}

// YOLO V5 REAL-TIME OBJECT DETECTION

class YoloVideo extends StatefulWidget {
  const YoloVideo({super.key});

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController controller;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;

  late FlutterVision vision; // YOLO

  @override
  void initState() {
    super.initState();

    vision = FlutterVision(); // YOLO

    init();
  }

  init() async {
    cameras = await availableCameras();
    controller =
        CameraController(cameras[0], ResolutionPreset.max, enableAudio: false);
    controller.initialize().then((value) {
      loadYoloModel().then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = false;
          yoloResults = [];

          startDetection();
        });
      });
    });
  }

  @override
  void dispose() async {
    vision.closeYoloModel(); // YOLO Stop

    super.dispose();
    controller.dispose();
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

                // YOLO 결과에서 첫 번째 태그 추출
                final String firstTag = yoloResults.isNotEmpty
                    ? yoloResults.map((result) => result['tag'] as String).first
                    : "Unknown";

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InsertPage(
                      data: firstTag,
                      imagePath: imageFile.path, // File path 전달
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
        numThreads: 8,
        useGpu: true);
    setState(() {
      isLoaded = true;
    });
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
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  // 객체 인식 종료
  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
