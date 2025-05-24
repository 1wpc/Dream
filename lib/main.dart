import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utills/env.dart';
import 'pages/dream_core_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
// 如需打字机动画可引入 animated_text_kit 包，暂用自定义动画

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '白日做梦',
      theme: ThemeData.dark(),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _fullText = '这里是一句未来将由API获取的梦境语录'; // 默认语句
  bool _navigated = false;
  late Future<String> _dailyWordFuture;

  @override
  void initState() {
    super.initState();
    _dailyWordFuture = _fetchDailyWord();
  }

  Future<String> _fetchDailyWord() async {
    try {
      final appId = Env.yijuAppId;
      final appSecret = Env.yijuAppSc;
      final url = Uri.parse('https://www.mxnzp.com/api/daily_word/recommend?count=1&app_id=$appId&app_secret=$appSecret');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 1 && data['data'] != null && data['data'].isNotEmpty) {
          return data['data'][0]['content'] ?? _fullText;
        }
      }
      return _fullText;
    } catch (e) {
      // 网络异常时保留默认语句
      return _fullText;
    }
  }

  void _goToMainPage() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DreamCorePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB2BCC6),
                  Color(0xFF8A9BA8),
                  Color(0xFF6D7B8A),
                ],
              ),
            ),
          ),
          // 右上角跳过按钮
          Positioned(
            top: 40,
            right: 24,
            child: ElevatedButton(
              onPressed: _goToMainPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                elevation: 0,
              ),
              child: const Text('跳过'),
            ),
          ),
          // 中间打字机动画文字 - 使用FutureBuilder
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FutureBuilder<String>(
                future: _dailyWordFuture,
                builder: (context, snapshot) {
                  // 处理不同的连接状态
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      // 当Future正在加载时，显示加载指示器或默认文本
                      return const CircularProgressIndicator();
                    case ConnectionState.done:
                      // 当Future完成时
                      if (snapshot.hasError) {
                        // 处理错误情况
                        return Text('加载失败: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        // 成功获取数据
                        return AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText(
                              snapshot.data!,
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                              textAlign: TextAlign.center,
                              speed: const Duration(milliseconds: 80),
                            ),
                          ],
                          isRepeatingAnimation: false,
                          onFinished: _goToMainPage,
                          displayFullTextOnTap: true,
                          stopPauseOnTap: true,
                        );
                      }
                      break;
                    default:
                      // 其他状态
                      break;
                  }
                  
                  // 默认情况下显示默认文本
                  return AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        _fullText,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                        textAlign: TextAlign.center,
                        speed: const Duration(milliseconds: 300),
                      ),
                    ],
                    isRepeatingAnimation: false,
                    onFinished: _goToMainPage,
                    displayFullTextOnTap: true,
                    stopPauseOnTap: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
