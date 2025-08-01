import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/dream_models.dart';
import 'main_container_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _loginTabController;
  late TabController _registerTabController;
  
  bool _isLoading = false;

  // 验证码倒计时
  int _loginCodeCountdown = 0;
  int _registerCodeCountdown = 0;
  Timer? _loginCodeTimer;
  Timer? _registerCodeTimer;

  // 登录表单控制器
  final TextEditingController _loginUsernameController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginCodeController = TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginEmailCodeController = TextEditingController();

  // 注册表单控制器
  final TextEditingController _registerPasswordController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerEmailCodeController = TextEditingController();
  final TextEditingController _registerDisplayNameController = TextEditingController();
  final TextEditingController _registerPhoneController = TextEditingController();
  final TextEditingController _registerPhoneCodeController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _loginTabController = TabController(length: 3, vsync: this);
    _registerTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _loginCodeTimer?.cancel();
    _registerCodeTimer?.cancel();
    
    _mainTabController.dispose();
    _loginTabController.dispose();
    _registerTabController.dispose();
    
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _loginPhoneController.dispose();
    _loginCodeController.dispose();
    _loginEmailController.dispose();
    _loginEmailCodeController.dispose();
    
    _registerPasswordController.dispose();
    _registerEmailController.dispose();
    _registerEmailCodeController.dispose();
    _registerDisplayNameController.dispose();
    _registerPhoneController.dispose();
    _registerPhoneCodeController.dispose();

    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1B3A),
              Color(0xFF2D1B69),
              Color(0xFF1A1B3A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部标题区域
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 60,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '白日做梦',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '探索梦境的无限可能',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // 主Tab栏（登录/注册）
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _mainTabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
                    ),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: '登录'),
                    Tab(text: '注册'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 内容区域
              Expanded(
                child: TabBarView(
                  controller: _mainTabController,
                  children: [
                    _buildLoginModule(),
                    _buildRegisterModule(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 登录模块
  Widget _buildLoginModule() {
    return Column(
      children: [
        // 登录方式Tab栏
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TabBar(
            controller: _loginTabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.1),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(text: '用户名'),
              Tab(text: '手机号'),
              Tab(text: '邮箱'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 登录内容
        Expanded(
          child: TabBarView(
            controller: _loginTabController,
            children: [
              _buildUsernameLogin(),
              _buildPhoneLogin(),
              _buildEmailLogin(),
            ],
          ),
        ),
      ],
    );
  }

  // 注册模块
  Widget _buildRegisterModule() {
    return Column(
      children: [
        // 注册方式Tab栏
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TabBar(
            controller: _registerTabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.1),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: '手机号注册'),
              Tab(text: '邮箱注册'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 注册内容
        Expanded(
          child: TabBarView(
            controller: _registerTabController,
            children: [
              _buildPhoneRegister(),
              _buildEmailRegister(),
            ],
          ),
        ),
      ],
    );
  }

  // 用户名密码登录
  Widget _buildUsernameLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildInputField(
            controller: _loginUsernameController,
            label: '用户名/手机号/邮箱',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _loginPasswordController,
            label: '密码',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            '登录',
            () => _handleUsernameLogin(),
          ),
        ],
      ),
    );
  }

  // 手机号登录
  Widget _buildPhoneLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildInputField(
            controller: _loginPhoneController,
            label: '手机号',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _loginCodeController,
                  label: '验证码',
                  icon: Icons.verified_user_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              _buildSendCodeButton(isLogin: true),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            '登录',
            () => _handlePhoneLogin(),
          ),
        ],
      ),
    );
  }





  // 手机号注册
  Widget _buildPhoneRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildInputField(
            controller: _registerPhoneController,
            label: '手机号',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _registerPhoneCodeController,
                  label: '验证码',
                  icon: Icons.verified_user_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              _buildSendCodeButton(isLogin: false),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _registerPasswordController,
            label: '密码',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _registerDisplayNameController,
            label: '昵称',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            '注册',
            () => _handlePhoneRegister(),
          ),
        ],
      ),
    );
  }

  // 输入框组件
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // 邮箱注册
  Widget _buildEmailRegister() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildInputField(
            controller: _registerEmailController,
            label: '邮箱',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _registerEmailCodeController,
                  label: '验证码',
                  icon: Icons.verified_user_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              _buildSendCodeButton(isLogin: false),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _registerPasswordController,
            label: '密码',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _registerDisplayNameController,
            label: '昵称',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            '注册',
            () => _handleEmailRegister(),
          ),
        ],
      ),
    );
  }

  // 邮箱验证码登录
  Widget _buildEmailLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildInputField(
            controller: _loginEmailController,
            label: '邮箱',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _loginEmailCodeController,
                  label: '验证码',
                  icon: Icons.verified_user_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              _buildSendCodeButton(isLogin: true),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            '登录',
            () => _handleEmailLogin(),
          ),
        ],
      ),
    );
  }

  // 发送验证码按钮
  Widget _buildSendCodeButton({bool isLogin = false}) {
    final countdown = isLogin ? _loginCodeCountdown : _registerCodeCountdown;
    final isCountingDown = countdown > 0;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isCountingDown ? null : const LinearGradient(
          colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
        ),
        color: isCountingDown ? Colors.grey : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: isCountingDown ? null : () {
          _sendVerificationCodeForCurrentTab(isLogin);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          isCountingDown ? '${countdown}s' : '发送',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 操作按钮
  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B73FF), Color(0xFF9B59B6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B73FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // 处理用户名登录
  Future<void> _handleUsernameLogin() async {
    if (_loginUsernameController.text.isEmpty || _loginPasswordController.text.isEmpty) {
      _showMessage('请填写完整信息');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 使用用户名替代邮箱进行登录
      final user = await authService.signInWithEmail(
        _loginUsernameController.text, // 这里传入用户名
        _loginPasswordController.text,
      );

      if (user != null) {
        _navigateToHome();
      } else {
        _showMessage('登录失败，请检查用户名和密码');
      }
    } catch (e) {
      _showMessage('登录失败：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 处理手机号登录
  Future<void> _handlePhoneLogin() async {
    if (_loginPhoneController.text.isEmpty || _loginCodeController.text.isEmpty) {
      _showMessage('请填写完整信息');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signInWithPhone(
        _loginPhoneController.text,
        _loginCodeController.text,
      );

      if (user != null) {
        _navigateToHome();
      } else {
        _showMessage('登录失败，请检查手机号和验证码');
      }
    } catch (e) {
      _showMessage('登录失败：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 处理邮箱验证码登录
  Future<void> _handleEmailLogin() async {
    if (_loginEmailController.text.isEmpty || _loginEmailCodeController.text.isEmpty) {
      _showMessage('请填写完整信息');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signInWithEmailCode(
        _loginEmailController.text,
        _loginEmailCodeController.text,
      );
      
      if (user != null) {
        _navigateToHome();
      } else {
        _showMessage('登录失败，请检查邮箱和验证码');
      }
    } catch (e) {
      _showMessage('登录失败：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }





  // 处理邮箱注册
  Future<void> _handleEmailRegister() async {
    if (_registerEmailController.text.isEmpty ||
        _registerEmailCodeController.text.isEmpty ||
        _registerPasswordController.text.isEmpty ||
        _registerDisplayNameController.text.isEmpty) {
      _showMessage('请填写完整信息');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.registerWithVerification(
        email: _registerEmailController.text,
        password: _registerPasswordController.text,
        verificationCode: _registerEmailCodeController.text,
        displayName: _registerDisplayNameController.text,
      );
      
      if (user != null) {
        _showMessage('注册成功！欢迎使用梦核');
        _navigateToHome();
      } else {
        _showMessage('注册失败，请检查信息');
      }
    } catch (e) {
      _showMessage('注册失败：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 处理手机号注册
  Future<void> _handlePhoneRegister() async {
    if (_registerPhoneController.text.isEmpty ||
        _registerPhoneCodeController.text.isEmpty ||
        _registerPasswordController.text.isEmpty ||
        _registerDisplayNameController.text.isEmpty) {
      _showMessage('请填写完整信息');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.registerWithPhone(
        username: _registerPhoneController.text, // 使用手机号作为用户名
        phone: _registerPhoneController.text,
        password: _registerPasswordController.text,
        verificationCode: _registerPhoneCodeController.text,
        fullName: _registerDisplayNameController.text,
      );
      
      if (user != null) {
        _showMessage('注册成功！欢迎使用梦核');
        _navigateToHome();
      } else {
        _showMessage('注册失败，请检查信息');
      }
    } catch (e) {
      _showMessage('注册失败：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainContainerPage()),
    );
  }

  // 根据当前tab发送验证码
  Future<void> _sendVerificationCodeForCurrentTab(bool isLogin) async {
    // 判断当前是在哪个tab
    if (isLogin) {
      if (_loginTabController.index == 1) {
        // 手机号登录
        await _sendSMSVerificationCode(isLogin);
      } else if (_loginTabController.index == 2) {
        // 邮箱登录
        await _sendEmailVerificationCode(isLogin);
      }
    } else {
      if (_registerTabController.index == 0) {
        // 手机号注册
        await _sendSMSVerificationCode(isLogin);
      } else if (_registerTabController.index == 1) {
        // 邮箱注册
        await _sendEmailVerificationCode(isLogin);
      }
    }
  }

  // 发送手机号验证码
  Future<void> _sendSMSVerificationCode(bool isLogin) async {
    String phone;
    String action;
    
    if (isLogin) {
      phone = _loginPhoneController.text;
      action = 'login';
    } else {
      phone = _registerPhoneController.text;
      action = 'register';
    }
    
    if (phone.isEmpty) {
      _showMessage('请先输入手机号');
      return;
    }
    
    // 验证手机号格式
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showMessage('请输入正确的手机号格式');
      return;
    }
    
    try {
      final request = SMSVerificationRequest(
        phone: phone,
        action: action,
      );
      final response = await ApiService.sendSMSVerificationCode(request);
      
      if (response.success) {
        _showMessage('验证码已发送到您的手机');
        _startCountdown(isLogin);
      } else {
        _showMessage(response.message);
      }
    } catch (e) {
      if (e is ApiException) {
        _showMessage(e.message);
      } else {
        _showMessage('发送验证码失败：$e');
      }
    }
  }

  // 发送邮箱验证码
  Future<void> _sendEmailVerificationCode(bool isLogin) async {
    String email;
    String action;
    
    if (isLogin) {
      email = _loginEmailController.text;
      action = 'login';
    } else {
      email = _registerEmailController.text;
      action = 'register';
    }
    
    if (email.isEmpty) {
      _showMessage('请先输入邮箱地址');
      return;
    }
    
    // 验证邮箱格式
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showMessage('请输入正确的邮箱格式');
      return;
    }
    
    try {
      final request = EmailVerificationRequest(
        email: email,
        action: action,
      );
      final response = await ApiService.sendVerificationCode(request);
      
      if (response.success) {
        _showMessage('验证码已发送到您的邮箱');
        _startCountdown(isLogin);
      } else {
        _showMessage(response.message);
      }
    } catch (e) {
      if (e is ApiException) {
        _showMessage(e.message);
      } else {
        _showMessage('发送验证码失败：$e');
      }
    }
  }
  
  // 开始倒计时
  void _startCountdown(bool isLogin) {
    if (isLogin) {
      setState(() => _loginCodeCountdown = 60);
      _loginCodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_loginCodeCountdown > 0) {
            _loginCodeCountdown--;
          } else {
            timer.cancel();
          }
        });
      });
    } else {
      setState(() => _registerCodeCountdown = 60);
      _registerCodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_registerCodeCountdown > 0) {
            _registerCodeCountdown--;
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6B73FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}