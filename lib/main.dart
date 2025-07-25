import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../utills/env.dart';
import 'pages/main_container_page.dart';
import 'pages/login_page.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/payment_service.dart';
import 'services/privacy_service.dart';
import 'widgets/privacy_policy_dialog.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化API服务
  try {
    ApiService.init();
    print('API服务初始化成功');
    
    // 检查API连接状态
    final isConnected = await ApiService.checkConnection();
    if (isConnected) {
      print('后端API连接正常');
    } else {
      print('后端API连接失败，将使用本地存储模式');
    }
  } catch (e) {
    print('API服务初始化失败: $e');
  }
  
  // 初始化支付服务
  try {
    PaymentService().initialize();
    print('支付服务初始化成功');
  } catch (e) {
    print('支付服务初始化失败: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
      title: '白日做梦',
      theme: ThemeData.dark(),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
      ),
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
  bool _showPrivacyDialog = false;
  late Future<String> _dailyWordFuture;

  @override
  void initState() {
    super.initState();
    _dailyWordFuture = _fetchDailyWord();
    _checkPrivacyPolicyAndInitialize();
  }

  // 检查隐私政策并初始化
  Future<void> _checkPrivacyPolicyAndInitialize() async {
    final hasAgreed = await PrivacyService.hasAgreedToPrivacyPolicy();
    
    if (!hasAgreed) {
      setState(() {
        _showPrivacyDialog = true;
      });
    } else {
      _initializeAuth();
    }
  }
  
  // 初始化身份认证
  Future<void> _initializeAuth() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // 尝试初始化认证状态
      await authService.initAuth();
    } catch (e) {
      print('初始化身份认证失败: $e');
      // 如果API认证失败，尝试从本地加载用户信息
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.loadUserProfileFromLocal();
    }
  }
  
  // 处理隐私政策同意
  void _handlePrivacyAgreed() {
    setState(() {
      _showPrivacyDialog = false;
    });
    _initializeAuth();
  }
  
  // 处理隐私政策不同意
  void _handlePrivacyDisagreed() {
    SystemNavigator.pop(); // 退出应用
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
    
    // 根据登录状态导航到不同页面
    final authService = Provider.of<AuthService>(context, listen: false);
    final targetPage = authService.isLoggedIn ? const MainContainerPage() : const LoginPage();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => targetPage),
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
          // 右上角跳过按钮（仅在不显示隐私弹窗时显示）
          if (!_showPrivacyDialog)
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
          // 中间打字机动画文字 - 使用FutureBuilder（仅在不显示隐私弹窗时显示）
          if (!_showPrivacyDialog)
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
          // 隐私政策弹窗
          if (_showPrivacyDialog)
            PrivacyPolicyDialog(
              onAgree: _handlePrivacyAgreed,
              onDisagree: _handlePrivacyDisagreed,
            ),
        ],
      ),
    );
  }
}
