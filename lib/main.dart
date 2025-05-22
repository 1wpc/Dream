import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'pages/dream_core_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '白日做梦',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DreamHomePage(),
    );
  }
}

class DreamHomePage extends StatefulWidget {
  const DreamHomePage({super.key});

  @override
  State<DreamHomePage> createState() => _DreamHomePageState();
}

class _DreamHomePageState extends State<DreamHomePage> {
  late Future<VideoPlayerController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _initializeVideo();
  }

  Future<VideoPlayerController> _initializeVideo() async {
    final controller = VideoPlayerController.asset('assets/videos/background.mp4');
    await controller.initialize();
    await controller.play();
    controller.setLooping(true);
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 视频背景
          FutureBuilder<VideoPlayerController>(
            future: _controllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '视频加载失败: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: Text('无法加载视频'),
                );
              }

              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: snapshot.data!.value.size?.width ?? 0,
                    height: snapshot.data!.value.size?.height ?? 0,
                    child: VideoPlayer(snapshot.data!),
                  ),
                ),
              );
            },
          ),
          // 底部按钮
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DreamCorePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  '进入梦核',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
