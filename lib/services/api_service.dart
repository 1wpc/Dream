import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/dream_models.dart';
import '../utills/env.dart';

/// HTTP API服务类
/// 负责与后端API进行交互
class ApiService {
  static late Dio _dio;
  static const _secureStorage = FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static DateTime? _tokenExpiry;
  static bool _isRefreshing = false;

  /// 初始化API服务
  static void init() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.backendApiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 配置HTTPS证书处理（Dio 5.x）
    _dio.httpClientAdapter = IOHttpClientAdapter(
      onHttpClientCreate: (client) {
        client.badCertificateCallback = (cert, host, port) {
          return true; // 接受所有证书（仅用于开发环境）
        };
        return client;
      },
    );

    // 添加请求拦截器，自动添加认证头和处理token刷新
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 检查token是否需要刷新
        await _checkAndRefreshToken();
        
        final token = await getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 如果是401错误（未授权），尝试刷新token
        if (error.response?.statusCode == 401) {
          try {
            await refreshToken();
            // 重试原请求
            final token = await getAccessToken();
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (e) {
            // 刷新失败，清除所有token
            await clearAllTokens();
          }
        }
        handler.next(error);
      },
    ));

    // 添加日志拦截器（仅在调试模式下）
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[API] $obj'),
    ));
  }

  /// 保存认证token（双重token）
  static Future<void> saveTokens(AuthToken authToken) async {
    _cachedAccessToken = authToken.accessToken;
    _cachedRefreshToken = authToken.refreshToken;
    _tokenExpiry = DateTime.now().add(Duration(seconds: authToken.expiresIn));
    
    await _secureStorage.write(key: _accessTokenKey, value: authToken.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: authToken.refreshToken);
    await _secureStorage.write(key: _tokenExpiryKey, value: _tokenExpiry!.toIso8601String());
  }

  /// 保存单个access token（用于兼容旧代码）
  static Future<void> saveToken(String token) async {
    _cachedAccessToken = token;
    // 为单token设置默认过期时间（1小时），避免自动刷新逻辑出错
    _tokenExpiry = DateTime.now().add(Duration(hours: 1));
    
    await _secureStorage.write(key: _accessTokenKey, value: token);
    await _secureStorage.write(key: _tokenExpiryKey, value: _tokenExpiry!.toIso8601String());
  }

  /// 获取access token
  static Future<String?> getAccessToken() async {
    _cachedAccessToken ??= await _secureStorage.read(key: _accessTokenKey);
    return _cachedAccessToken;
  }

  /// 获取refresh token
  static Future<String?> getRefreshToken() async {
    _cachedRefreshToken ??= await _secureStorage.read(key: _refreshTokenKey);
    return _cachedRefreshToken;
  }

  /// 获取token过期时间
  static Future<DateTime?> getTokenExpiry() async {
    if (_tokenExpiry == null) {
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        _tokenExpiry = DateTime.tryParse(expiryStr);
      }
    }
    return _tokenExpiry;
  }

  /// 获取认证token（兼容旧代码）
  static Future<String?> getToken() async {
    return await getAccessToken();
  }

  /// 清除所有认证token
  static Future<void> clearAllTokens() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _tokenExpiry = null;
    _isRefreshing = false;
    
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _tokenExpiryKey);
  }

  /// 清除认证token（兼容旧代码）
  static Future<void> clearToken() async {
    await clearAllTokens();
  }

  /// 用户注册
  /// 
  /// [request] 注册请求数据
  /// 返回注册成功的用户信息
  static Future<ApiUser> register(UserCreateRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/register',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        // 从响应中提取用户信息
        final userResponse = response.data;
        return ApiUser.fromJson(userResponse['user']);
      } else {
        throw ApiException('注册失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'] ?? [];
        if (errors.isNotEmpty) {
          final firstError = errors[0]['msg'] ?? '';
          if (firstError.contains('username')) {
            throw ApiException('用户名已存在', 422);
          } else if (firstError.contains('email')) {
            throw ApiException('邮箱已被注册', 422);
          } else if (firstError.contains('phone')) {
            throw ApiException('手机号已被注册', 422);
          }
        }
        throw ApiException('注册信息有误', 422);
      } else if (e.response?.statusCode == 429) {
        throw ApiException('注册请求过于频繁，请稍后再试', 429);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('注册失败', null);
    }
  }

  /// 用户登录
  /// 
  /// [request] 登录请求数据
  /// 返回认证token
  static Future<AuthToken> login(UserLoginRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/login',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final token = AuthToken.fromJson(response.data);
        await saveTokens(token);
        return token;
      } else {
        throw ApiException('登录失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('用户名或密码错误', 401);
      } else if (e.response?.statusCode == 422) {
        throw ApiException('用户名或密码错误', 422);
      } else if (e.response?.statusCode == 429) {
        throw ApiException('登录尝试过于频繁，请稍后再试', 429);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('登录失败', null);
    }
  }

  /// 获取当前用户信息
  /// 
  /// 需要用户已登录（有有效token）
  static Future<ApiUser> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/v1/users/me');

      if (response.statusCode == 200) {
        return ApiUser.fromJson(response.data);
      } else {
        throw ApiException('获取用户信息失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw ApiException('登录已过期，请重新登录', 401);
      } else if (e.response?.statusCode == 403) {
        throw ApiException('权限不足', 403);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('获取用户信息失败', null);
    }
  }

  /// 更新当前用户信息
  /// 
  /// [request] 更新请求数据
  /// 返回更新后的用户信息
  static Future<ApiUser> updateCurrentUser(UserUpdateRequest request) async {
    try {
      final response = await _dio.put(
        '/api/v1/users/me',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // 从响应中提取用户信息
        final userResponse = response.data;
        return ApiUser.fromJson(userResponse['user']);
      } else {
        throw ApiException('更新用户信息失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw ApiException('登录已过期，请重新登录', 401);
      } else if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'] ?? [];
        if (errors.isNotEmpty) {
          final firstError = errors[0]['msg'] ?? '';
          if (firstError.contains('nickname')) {
            throw ApiException('昵称格式不正确', 422);
          } else if (firstError.contains('email')) {
            throw ApiException('邮箱格式不正确', 422);
          } else if (firstError.contains('phone')) {
            throw ApiException('手机号格式不正确', 422);
          }
        }
        throw ApiException('输入信息格式不正确', 422);
      } else if (e.response?.statusCode == 403) {
        throw ApiException('权限不足', 403);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('更新用户资料失败', null);
    }
  }

  /// 发送邮箱验证码
  /// 
  /// [request] 验证码发送请求数据
  /// 返回发送结果
  static Future<EmailVerificationResponse> sendVerificationCode(EmailVerificationRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/send-verification-code',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return EmailVerificationResponse.fromJson(response.data);
      } else {
        throw ApiException('发送验证码失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'] ?? [];
        if (errors.isNotEmpty) {
          final firstError = errors[0]['msg'] ?? '';
          if (firstError.contains('email')) {
            throw ApiException('邮箱格式不正确', 422);
          } else if (firstError.contains('频繁') || firstError.contains('frequent')) {
            throw ApiException('发送过于频繁，请稍后再试', 422);
          }
        }
        throw ApiException('邮箱格式不正确', 422);
      } else if (e.response?.statusCode == 429) {
        throw ApiException('发送过于频繁，请稍后再试', 429);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('发送验证码失败', null);
    }
  }

  /// 验证邮箱验证码
  /// 
  /// [request] 验证码验证请求数据
  /// 返回验证结果
  static Future<EmailVerificationResponse> verifyEmailCode(EmailCodeVerifyRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/verify-email-code',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return EmailVerificationResponse.fromJson(response.data);
      } else {
        throw ApiException('验证码验证失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('验证码错误或已过期', 401);
      } else if (e.response?.statusCode == 422) {
        throw ApiException('验证码格式不正确', 422);
      } else if (e.response?.statusCode == 429) {
        throw ApiException('验证尝试过于频繁，请稍后再试', 429);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('验证失败', null);
    }
  }

  /// 带验证码的用户注册
  /// 
  /// [request] 注册请求数据（包含验证码）
  /// 返回注册响应（包含用户信息和token）
  static Future<UserRegisterResponse> registerWithVerification(UserCreateWithVerificationRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/register-with-verification',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        // 从响应中提取完整的注册信息
        final registerResponse = UserRegisterResponse.fromJson(response.data);
        // 自动保存token（如果响应包含refresh token则使用双重token）
        if (registerResponse.refreshToken != null) {
          final authToken = AuthToken(
            accessToken: registerResponse.accessToken,
            refreshToken: registerResponse.refreshToken!,
            tokenType: 'bearer',
            expiresIn: 3600,
          );
          await saveTokens(authToken);
        } else {
          await saveToken(registerResponse.accessToken);
        }
        return registerResponse;
      } else {
        throw ApiException('注册失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        // 验证错误
        final errors = e.response?.data['detail'] ?? [];
        final errorMessages = errors.map((error) => error['msg']).join(', ');
        throw ApiException('注册失败: $errorMessages', 422);
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('注册失败: $e', null);
    }
  }

  /// 邮箱验证码登录
  /// 
  /// [request] 邮箱验证码登录请求数据
  /// 返回认证token
  static Future<AuthToken> loginWithEmailCode(EmailLoginRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/login-with-email-verification',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final token = AuthToken.fromJson(response.data);
        await saveTokens(token);
        return token;
      } else {
        throw ApiException('登录失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('邮箱或验证码错误', 401);
      } else if (e.response?.statusCode == 422) {
        throw ApiException('邮箱或验证码错误', 422);
      } else if (e.response?.statusCode == 429) {
        throw ApiException('登录尝试过于频繁，请稍后再试', 429);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('登录失败', null);
    }
  }

  /// 发送手机号验证码
  /// 
  /// [request] 手机号验证码发送请求数据
  /// 返回发送结果
  static Future<SMSVerificationResponse> sendSMSVerificationCode(SMSVerificationRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/send-sms-verification-code',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return SMSVerificationResponse.fromJson(response.data);
      } else {
        throw ApiException('发送短信验证码失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'] ?? [];
        if (errors.isNotEmpty) {
          final firstError = errors[0]['msg'] ?? '';
          if (firstError.contains('phone')) {
            throw ApiException('手机号格式不正确', 422);
          } else if (firstError.contains('频繁') || firstError.contains('frequent')) {
            throw ApiException('发送过于频繁，请稍后再试', 422);
          }
        }
        throw ApiException('手机号格式不正确', 422);
      } else if (e.response?.statusCode == 429) {
        throw ApiException('发送过于频繁，请稍后再试', 429);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('发送验证码失败', null);
    }
  }

  /// 验证手机号验证码
  /// 
  /// [request] 手机号验证码验证请求数据
  /// 返回验证结果
  static Future<SMSVerificationResponse> verifySMSCode(SMSCodeVerifyRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/verify-sms-code',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return SMSVerificationResponse.fromJson(response.data);
      } else {
        throw ApiException('短信验证码验证失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('验证码错误或已过期', 401);
      } else if (e.response?.statusCode == 422) {
        throw ApiException('验证码格式不正确', 422);
      } else if (e.response?.statusCode == 429) {
        throw ApiException('验证尝试过于频繁，请稍后再试', 429);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('验证失败', null);
    }
  }

  /// 手机号验证码登录
  /// 
  /// [request] 手机号验证码登录请求数据
  /// 返回认证token
  static Future<AuthToken> loginWithSMSVerification(SMSLoginRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/login-with-sms-verification',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final token = AuthToken.fromJson(response.data);
        await saveTokens(token);
        return token;
      } else {
        throw ApiException('手机号登录失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('手机号或验证码错误', 401);
      } else if (e.response?.statusCode == 422) {
        throw ApiException('手机号或验证码错误', 422);
      } else if (e.response?.statusCode == 429) {
        throw ApiException('登录尝试过于频繁，请稍后再试', 429);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw ApiException('网络连接超时', e.response?.statusCode);
      } else if (e.type == DioExceptionType.connectionError) {
        throw ApiException('网络连接失败', e.response?.statusCode);
      }
      throw ApiException('网络错误', e.response?.statusCode);
    } catch (e) {
      throw ApiException('登录失败', null);
    }
  }

  /// 带手机号验证码的用户注册
  /// 
  /// [request] 手机号注册请求数据（包含验证码）
  /// 返回注册响应（包含用户信息和token）
  static Future<UserRegisterResponse> registerWithSMSVerification(UserCreateWithSMSVerificationRequest request) async {
    try {
      final response = await _dio.post(
        '/api/v1/users/register-with-sms-verification',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        // 从响应中提取完整的注册信息
        final registerResponse = UserRegisterResponse.fromJson(response.data);
        // 自动保存token（如果响应包含refresh token则使用双重token）
        if (registerResponse.refreshToken != null) {
          final authToken = AuthToken(
            accessToken: registerResponse.accessToken,
            refreshToken: registerResponse.refreshToken!,
            tokenType: 'bearer',
            expiresIn: 3600,
          );
          await saveTokens(authToken);
        } else {
          await saveToken(registerResponse.accessToken);
        }
        return registerResponse;
      } else {
        throw ApiException('手机号注册失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        // 验证错误
        final errors = e.response?.data['detail'] ?? [];
        final errorMessages = errors.map((error) => error['msg']).join(', ');
        throw ApiException('手机号注册失败: $errorMessages', 422);
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('手机号注册失败: $e', null);
    }
  }

  /// 检查API连接状态
  static Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 刷新访问令牌
  static Future<AccessTokenResponse> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw ApiException('没有可用的刷新令牌', 401);
      }

      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await _dio.post(
        '/api/v1/users/refresh-token',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final accessTokenResponse = AccessTokenResponse.fromJson(response.data);
        
        // 更新access token和过期时间
        _cachedAccessToken = accessTokenResponse.accessToken;
        _tokenExpiry = DateTime.now().add(Duration(seconds: accessTokenResponse.expiresIn));
        
        await _secureStorage.write(key: _accessTokenKey, value: accessTokenResponse.accessToken);
        await _secureStorage.write(key: _tokenExpiryKey, value: _tokenExpiry!.toIso8601String());
        
        return accessTokenResponse;
      } else {
        throw ApiException('刷新令牌失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // 刷新令牌无效，清除所有token
        await clearAllTokens();
        throw ApiException('刷新令牌已过期，请重新登录', 401);
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('刷新令牌失败: $e', null);
    }
  }

  /// 检查并自动刷新token
  static Future<void> _checkAndRefreshToken() async {
    try {
      // 如果正在刷新中，直接返回
      if (_isRefreshing) {
        return;
      }
      
      final expiry = await getTokenExpiry();
      final refreshTokenValue = await getRefreshToken();
      
      // 只有在有refresh token和过期时间的情况下才进行自动刷新
      if (expiry != null && refreshTokenValue != null) {
        final now = DateTime.now();
        final timeUntilExpiry = expiry.difference(now);
        
        // 如果token在5分钟内过期，则刷新
        if (timeUntilExpiry.inMinutes <= 5 && timeUntilExpiry.inSeconds > 0) {
          _isRefreshing = true;
          print('Token即将过期，自动刷新中...');
          await refreshToken();
          print('Token刷新成功');
          _isRefreshing = false;
        }
      }
    } catch (e) {
      _isRefreshing = false;
      print('自动刷新token失败: $e');
      // 不抛出异常，让请求继续进行
    }
  }

  /// 检查token是否有效
  static Future<bool> isTokenValid() async {
    try {
      final expiry = await getTokenExpiry();
      if (expiry == null) return false;
      
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  /// 获取Dio实例（用于其他服务扩展使用）
  static Dio get dio => _dio;
}

/// API异常类
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (状态码: $statusCode)';
}