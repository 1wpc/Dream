import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';
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
                    Text(
                      AppLocalizations.of(context)!.dayDream,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.exploreInfinitePossibilities,
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
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.login),
            Tab(text: AppLocalizations.of(context)!.register),
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
              
              // 语言切换按钮
              _buildLanguageSwitch(),
              
              const SizedBox(height: 20),
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
            tabs: [
              Tab(text: AppLocalizations.of(context)!.username),
                      Tab(text: AppLocalizations.of(context)!.phone),
                      Tab(text: AppLocalizations.of(context)!.email),
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
            tabs: [
              Tab(text: AppLocalizations.of(context)!.phoneRegister),
                      Tab(text: AppLocalizations.of(context)!.emailRegister),
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
            label: AppLocalizations.of(context)!.usernamePhoneEmail,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _loginPasswordController,
            label: AppLocalizations.of(context)!.password,
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            AppLocalizations.of(context)!.login,
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
            label: AppLocalizations.of(context)!.phone,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _loginCodeController,
                  label: AppLocalizations.of(context)!.verificationCode,
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
              AppLocalizations.of(context)!.login,
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
            label: AppLocalizations.of(context)!.phoneNumber,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _registerPhoneCodeController,
                  label: AppLocalizations.of(context)!.verificationCodeLabel,
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
            label: AppLocalizations.of(context)!.passwordLabel,
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _registerDisplayNameController,
            label: AppLocalizations.of(context)!.nickname,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            AppLocalizations.of(context)!.register,
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
            label: AppLocalizations.of(context)!.emailLabel,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _registerEmailCodeController,
                  label: AppLocalizations.of(context)!.verificationCodeLabel,
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
            label: AppLocalizations.of(context)!.passwordLabel,
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _registerDisplayNameController,
            label: AppLocalizations.of(context)!.nicknameLabel,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 32),
          _buildActionButton(
            AppLocalizations.of(context)!.registerLabel,
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
            label: AppLocalizations.of(context)!.emailLabel,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _loginEmailCodeController,
                  label: AppLocalizations.of(context)!.verificationCodeLabel,
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
            AppLocalizations.of(context)!.loginLabel,
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
          isCountingDown ? '${countdown}s' : AppLocalizations.of(context)!.send,
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
      _showMessage(AppLocalizations.of(context)!.pleaseCompleteInfo);
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
        _showMessage(AppLocalizations.of(context)!.loginFailed);
      }
    } catch (e) {
      _showMessage('${AppLocalizations.of(context)!.loginFailedError}：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 处理手机号登录
  Future<void> _handlePhoneLogin() async {
    if (_loginPhoneController.text.isEmpty || _loginCodeController.text.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.pleaseCompleteAllInfo);
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
        _showMessage(AppLocalizations.of(context)!.loginFailedCheckPhone);
      }
    } catch (e) {
      _showMessage('${AppLocalizations.of(context)!.loginFailedError}：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 处理邮箱验证码登录
  Future<void> _handleEmailLogin() async {
    if (_loginEmailController.text.isEmpty || _loginEmailCodeController.text.isEmpty) {
      _showMessage(AppLocalizations.of(context)!.pleaseCompleteAllInfo);
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
        _showMessage(AppLocalizations.of(context)!.loginFailedCheckEmail);
      }
    } catch (e) {
      _showMessage('${AppLocalizations.of(context)!.loginFailedError}：$e');
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
      _showMessage(AppLocalizations.of(context)!.pleaseCompleteAllInfo);
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
        _showMessage(AppLocalizations.of(context)!.registerSuccess);
        _navigateToHome();
      } else {
        _showMessage(AppLocalizations.of(context)!.registerFailed);
      }
    } catch (e) {
      _showMessage('${AppLocalizations.of(context)!.registerFailedError}：$e');
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
      _showMessage(AppLocalizations.of(context)!.pleaseCompleteAllInfo);
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
        _showMessage(AppLocalizations.of(context)!.registerSuccessWelcome);
        _navigateToHome();
      } else {
        _showMessage(AppLocalizations.of(context)!.registerFailedCheckInfo);
      }
    } catch (e) {
      _showMessage('${AppLocalizations.of(context)!.registerFailedError}：$e');
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
      _showMessage(AppLocalizations.of(context)!.pleaseEnterPhone);
      return;
    }
    
    // 验证手机号格式
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showMessage(AppLocalizations.of(context)!.pleaseEnterCorrectPhone);
      return;
    }
    
    try {
      final request = SMSVerificationRequest(
        phone: phone,
        action: action,
      );
      final response = await ApiService.sendSMSVerificationCode(request);
      
      if (response.success) {
        _showMessage(AppLocalizations.of(context)!.verificationCodeSent);
        _startCountdown(isLogin);
      } else {
        _showMessage(response.message);
      }
    } catch (e) {
      if (e is ApiException) {
        _showMessage(e.message);
      } else {
        _showMessage('${AppLocalizations.of(context)!.sendVerificationCodeFailed}：$e');
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
      _showMessage(AppLocalizations.of(context)!.pleaseEnterEmail);
      return;
    }
    
    // 验证邮箱格式
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showMessage(AppLocalizations.of(context)!.pleaseEnterCorrectEmail);
      return;
    }
    
    try {
      final request = EmailVerificationRequest(
        email: email,
        action: action,
      );
      final response = await ApiService.sendVerificationCode(request);
      
      if (response.success) {
        _showMessage(AppLocalizations.of(context)!.verificationCodeSentToEmail);
        _startCountdown(isLogin);
      } else {
        _showMessage(response.message);
      }
    } catch (e) {
      if (e is ApiException) {
        _showMessage(e.message);
      } else {
        _showMessage('${AppLocalizations.of(context)!.sendVerificationCodeFailedError}：$e');
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
  
  // 构建语言切换组件
  Widget _buildLanguageSwitch() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.language,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _showLanguageDialog(languageService);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        languageService.isChinese ? '中文' : 'English',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 显示语言选择对话框
  void _showLanguageDialog(LanguageService languageService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D1B69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppLocalizations.of(context)!.selectLanguage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languageService.getSupportedLanguages().map((language) {
              final isSelected = languageService.currentLocale.languageCode == language['code'];
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? const Color(0xFF6B73FF) : Colors.white70,
                ),
                title: Text(
                  language['name']!,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF6B73FF) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  languageService.changeLanguage(language['code']!);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}