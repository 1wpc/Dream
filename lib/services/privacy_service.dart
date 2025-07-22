import 'package:shared_preferences/shared_preferences.dart';

class PrivacyService {
  static const String _privacyAgreedKey = 'privacy_policy_agreed';
  
  /// 检查用户是否已同意隐私政策
  static Future<bool> hasAgreedToPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyAgreedKey) ?? false;
  }
  
  /// 设置用户已同意隐私政策
  static Future<void> setPrivacyPolicyAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyAgreedKey, true);
  }
  
  /// 重置隐私政策同意状态（用于测试）
  static Future<void> resetPrivacyPolicyAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_privacyAgreedKey);
  }
}