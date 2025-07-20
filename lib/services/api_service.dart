import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/dream_models.dart';
import '../utills/env.dart';

/// HTTP API服务类
/// 负责与后端API进行交互
class ApiService {
  static late Dio _dio;
  static const _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static String? _cachedToken;

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

    // 添加请求拦截器，自动添加认证头
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 如果是401错误（未授权），清除本地token
        if (error.response?.statusCode == 401) {
          await clearToken();
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

  /// 保存认证token
  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// 获取认证token
  static Future<String?> getToken() async {
    _cachedToken ??= await _secureStorage.read(key: _tokenKey);
    return _cachedToken;
  }

  /// 清除认证token
  static Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: _tokenKey);
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
        await saveToken(token.accessToken);
        return token;
      } else {
        throw ApiException('登录失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('用户名或密码错误', 401);
      } else if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'] ?? [];
        final errorMessages = errors.map((error) => error['msg']).join(', ');
        throw ApiException('登录失败: $errorMessages', 422);
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('登录失败: $e', null);
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
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('获取用户信息失败: $e', null);
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
        final errorMessages = errors.map((error) => error['msg']).join(', ');
        throw ApiException('更新失败: $errorMessages', 422);
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('更新用户信息失败: $e', null);
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
        final errorMessages = errors.map((error) => error['msg']).join(', ');
        throw ApiException('发送验证码失败: $errorMessages', 422);
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('发送验证码失败: $e', null);
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
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'] ?? [];
        final errorMessages = errors.map((error) => error['msg']).join(', ');
        throw ApiException('验证码验证失败: $errorMessages', 422);
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('验证码验证失败: $e', null);
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
        // 自动保存token
        await saveToken(registerResponse.accessToken);
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
        await saveToken(token.accessToken);
        return token;
      } else {
        throw ApiException('登录失败', response.statusCode);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ApiException('邮箱或验证码错误', 401);
      } else if (e.response?.statusCode == 422) {
        final errors = e.response?.data['detail'] ?? [];
        final errorMessages = errors.map((error) => error['msg']).join(', ');
        throw ApiException('登录失败: $errorMessages', 422);
      }
      throw ApiException('网络错误: ${e.message}', e.response?.statusCode);
    } catch (e) {
      throw ApiException('登录失败: $e', null);
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