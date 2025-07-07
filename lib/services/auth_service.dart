import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../models/dream_models.dart';
import 'api_service.dart';

/// 身份认证服务类
/// 使用HTTP API与后端进行用户认证和管理
class AuthService extends ChangeNotifier {
  // 安全存储
  static const _secureStorage = FlutterSecureStorage();
  
  // 用户信息
  ApiUser? _currentApiUser;
  DreamUser? _userProfile;
  bool _isLoading = false;
  String? _authToken;

  /// 获取当前API用户
  ApiUser? get currentApiUser => _currentApiUser;
  
  /// 获取用户档案
  DreamUser? get userProfile => _userProfile;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 是否已登录
  bool get isLoggedIn => _currentApiUser != null && _authToken != null;

  /// 获取用户ID
  String? get userId => _currentApiUser?.id.toString();

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 显示提示消息
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// 初始化认证状态
  Future<void> initAuth() async {
    try {
      _setLoading(true);
      
      // 获取本地保存的token
      _authToken = await ApiService.getToken();
      
      if (_authToken != null) {
        // 尝试获取用户信息验证token有效性
        await _loadCurrentUser();
        print('用户已登录: ${_currentApiUser?.username}');
      } else {
        print('用户未登录');
      }
    } catch (e) {
      print('初始化认证状态失败: $e');
      // token可能已失效，清除本地数据
      await _clearLocalAuthData();
    } finally {
      _setLoading(false);
    }
  }

  /// 用户注册
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      
      final request = UserCreateRequest(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      
      final apiUser = await ApiService.register(request);
      _currentApiUser = apiUser;
      
      // 转换为应用内用户模型
      _userProfile = apiUser.toDreamUser();
      
      // 保存到本地存储
      await _saveUserProfile();
      
      _showToast('注册成功');
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _showToast(e.message);
      return false;
    } catch (e) {
      print('注册失败: $e');
      _showToast('注册失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 用户登录
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      _setLoading(true);
      
      final request = UserLoginRequest(
        username: username,
        password: password,
      );
      
      final authToken = await ApiService.login(request);
      _authToken = authToken.accessToken;
      
      // 获取用户信息
      await _loadCurrentUser();
      
      _showToast('登录成功');
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _showToast(e.message);
      return false;
    } catch (e) {
      print('登录失败: $e');
      _showToast('登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 匿名登录
  Future<DreamUser?> signInAnonymously() async {
    try {
      _setLoading(true);
      
      // 创建一个临时的匿名用户档案
      final anonymousUser = DreamUser(
        id: 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        nickname: '匿名用户',
        avatar: '',
        points: 100, // 匿名用户也有100积分
        dreamCount: 0,
        followersCount: 0,
        followingCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );
      
      _userProfile = anonymousUser;
      
      // 保存到本地存储
      await _saveUserProfile();
      
      _showToast('匿名登录成功');
      notifyListeners();
      return _userProfile;
    } catch (e) {
      print('匿名登录失败: $e');
      _showToast('匿名登录失败: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 匿名登录（保留兼容性）
  Future<bool> signInAnonymouslyCompat() async {
    final result = await signInAnonymously();
    return result != null;
  }

  /// 手机号登录
  Future<DreamUser?> signInWithPhone(String phone, String code) async {
    try {
      _setLoading(true);
      
      // 简单验证码验证（演示用）
      if (code != '1234') {
        throw Exception('验证码错误，请输入1234');
      }
      
      // 创建一个手机号用户档案
      final phoneUser = DreamUser(
        id: 'phone_${phone}_${DateTime.now().millisecondsSinceEpoch}',
        nickname: '用户${phone.substring(phone.length - 4)}',
        avatar: '',
        phone: phone,
        points: 100, // 新用户赠送100积分
        dreamCount: 0,
        followersCount: 0,
        followingCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'active',
      );
      
      _userProfile = phoneUser;
      
      // 保存到本地存储
      await _saveUserProfile();
      
      _showToast('手机号登录成功');
      notifyListeners();
      return _userProfile;
    } catch (e) {
      print('手机号登录失败: $e');
      _showToast('手机号登录失败: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 简单的手机号登录（演示用，保留兼容性）
  Future<bool> signInWithPhoneSimple({
    required String phone,
    required String code,
  }) async {
    final result = await signInWithPhone(phone, code);
    return result != null;
  }

  /// 用户名密码登录
  Future<DreamUser?> signInWithEmail(String username, String password) async {
    try {
      _setLoading(true);
      
      final request = UserLoginRequest(
        username: username, // 现在接受用户名
        password: password,
      );
      
      final authToken = await ApiService.login(request);
      _authToken = authToken.accessToken;
      
      // 获取用户信息
      await _loadCurrentUser();
      
      _showToast('登录成功');
      notifyListeners();
      return _userProfile;
    } on ApiException catch (e) {
      _showToast(e.message);
      return null;
    } catch (e) {
      print('用户名登录失败: $e');
      _showToast('用户名登录失败: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 邮箱密码登录（保持兼容性）
  Future<bool> signInWithEmailCompat({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      
      final request = UserLoginRequest(
        username: email, // 后端可以接受邮箱作为用户名
        password: password,
      );
      
      final authToken = await ApiService.login(request);
      _authToken = authToken.accessToken;
      
      // 获取用户信息
      await _loadCurrentUser();
      
      _showToast('登录成功');
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _showToast(e.message);
      return false;
    } catch (e) {
      print('邮箱登录失败: $e');
      _showToast('邮箱登录失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 用户名注册
  Future<DreamUser?> registerWithEmail(String username, String password, String displayName) async {
    try {
      _setLoading(true);
      
      final request = UserCreateRequest(
        username: username,
        email: '$username@dream.app', // 使用用户名生成临时邮箱
        password: password,
        fullName: displayName,
      );
      
      final apiUser = await ApiService.register(request);
      _currentApiUser = apiUser;
      
      // 转换为应用内用户模型
      _userProfile = apiUser.toDreamUser();
      
      // 保存到本地存储
      await _saveUserProfile();
      
      _showToast('注册成功');
      notifyListeners();
      return _userProfile;
    } on ApiException catch (e) {
      _showToast(e.message);
      return null;
    } catch (e) {
      print('用户名注册失败: $e');
      _showToast('用户名注册失败: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 邮箱注册（保持兼容性）
  Future<bool> registerWithEmailCompat({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      _setLoading(true);
      
      final request = UserCreateRequest(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );
      
      final apiUser = await ApiService.register(request);
      _currentApiUser = apiUser;
      
      // 转换为应用内用户模型
      _userProfile = apiUser.toDreamUser();
      
      // 保存到本地存储
      await _saveUserProfile();
      
      _showToast('注册成功');
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _showToast(e.message);
      return false;
    } catch (e) {
      print('邮箱注册失败: $e');
      _showToast('邮箱注册失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 简单的发送验证码（演示用，保留兼容性）
  Future<bool> sendVerificationCodeSimple(String phone) async {
    try {
      _setLoading(true);
      
      // 验证手机号格式
      if (phone.length != 11 || !phone.startsWith('1')) {
        throw Exception('请输入正确的手机号');
      }
      
      // 模拟发送验证码
      await Future.delayed(const Duration(seconds: 1));
      
      _showToast('验证码已发送（演示码：1234）');
      return true;
    } catch (e) {
      print('发送验证码失败: $e');
      _showToast('发送验证码失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 登出
  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      // 清除认证数据
      await _clearLocalAuthData();
      
      _showToast('已退出登录');
      notifyListeners();
    } catch (e) {
      print('登出失败: $e');
      _showToast('登出失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 更新用户档案
  Future<bool> updateUserProfile({
    String? nickname,
    String? avatar,
    String? bio,
    String? phone,
  }) async {
    try {
      if (_userProfile == null) {
        throw Exception('用户未登录');
      }
      
      _setLoading(true);
      
      // 如果是API用户，尝试通过API更新
      if (_currentApiUser != null && _authToken != null) {
        try {
          final updateRequest = UserUpdateRequest(
            fullName: nickname,
            phone: phone,
            avatar: avatar,
          );
          
          final updatedApiUser = await ApiService.updateCurrentUser(updateRequest);
          _currentApiUser = updatedApiUser;
          
          // 同步更新到DreamUser
          _userProfile = updatedApiUser.toDreamUser().copyWith(
            bio: bio, // bio字段API不支持，只在本地保存
          );
        } catch (e) {
          print('API更新失败，仅本地更新: $e');
          // API更新失败，仅本地更新
          _userProfile = _userProfile!.copyWith(
            nickname: nickname,
            avatar: avatar,
            bio: bio,
            phone: phone,
            updatedAt: DateTime.now(),
          );
        }
      } else {
        // 匿名用户或本地用户，仅本地更新
        _userProfile = _userProfile!.copyWith(
          nickname: nickname,
          avatar: avatar,
          bio: bio,
          phone: phone,
          updatedAt: DateTime.now(),
        );
      }
      
      // 保存到本地存储
      await _saveUserProfile();
      
      _showToast('个人信息更新成功');
      notifyListeners();
      return true;
    } catch (e) {
      print('更新用户档案失败: $e');
      _showToast('更新个人信息失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 增加用户积分
  Future<bool> addPoints(int points, String reason) async {
    try {
      if (_userProfile == null) return false;
      
      final newPoints = (_userProfile!.points ?? 0) + points;
      
      // 更新本地用户信息
      _userProfile = _userProfile!.copyWith(
        points: newPoints,
        updatedAt: DateTime.now(),
      );
      
      // 保存到本地存储
      await _saveUserProfile();
      
      _showToast('获得 $points 积分：$reason');
      notifyListeners();
      return true;
    } catch (e) {
      print('增加积分失败: $e');
      return false;
    }
  }

  /// 消费用户积分
  Future<bool> consumePoints(int points, String reason) async {
    try {
      if (_userProfile == null) return false;
      
      final currentPoints = _userProfile!.points ?? 0;
      if (currentPoints < points) {
        _showToast('积分不足');
        return false;
      }
      
      final newPoints = currentPoints - points;
      
      // 更新本地用户信息
      _userProfile = _userProfile!.copyWith(
        points: newPoints,
        updatedAt: DateTime.now(),
      );
      
      // 保存到本地存储
      await _saveUserProfile();
      
      _showToast('消费 $points 积分：$reason');
      notifyListeners();
      return true;
    } catch (e) {
      print('消费积分失败: $e');
      return false;
    }
  }

  /// 从本地存储加载用户档案
  Future<void> loadUserProfileFromLocal() async {
    try {
      final localProfile = await _secureStorage.read(key: 'user_profile');
      
      if (localProfile != null) {
        _userProfile = DreamUser.fromJson(jsonDecode(localProfile));
        print('从本地加载用户档案成功: ${_userProfile?.nickname}');
      }
    } catch (e) {
      print('从本地加载用户档案失败: $e');
    }
  }

  /// 加载当前用户信息
  Future<void> _loadCurrentUser() async {
    try {
      final apiUser = await ApiService.getCurrentUser();
      _currentApiUser = apiUser;
      _userProfile = apiUser.toDreamUser();
      
      // 保存到本地存储
      await _saveUserProfile();
    } catch (e) {
      print('加载用户信息失败: $e');
      throw e;
    }
  }

  /// 保存用户档案到本地存储
  Future<void> _saveUserProfile() async {
    if (_userProfile != null) {
      await _secureStorage.write(
        key: 'user_profile',
        value: jsonEncode(_userProfile!.toJson()),
      );
    }
  }

  /// 清除本地认证数据
  Future<void> _clearLocalAuthData() async {
    await ApiService.clearToken();
    await _secureStorage.deleteAll();
    
    _authToken = null;
    _currentApiUser = null;
    _userProfile = null;
  }
} 