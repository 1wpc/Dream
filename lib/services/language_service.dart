import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('zh'); // 默认中文
  
  Locale get currentLocale => _currentLocale;
  
  LanguageService() {
    _loadLanguage();
  }
  
  // 加载保存的语言设置
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'zh';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }
  
  // 切换语言
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }
  
  // 获取支持的语言列表
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'zh', 'name': '中文', 'englishName': 'Chinese'},
      {'code': 'en', 'name': 'English', 'englishName': 'English'},
    ];
  }
  
  // 判断是否为中文
  bool get isChinese => _currentLocale.languageCode == 'zh';
  
  // 判断是否为英文
  bool get isEnglish => _currentLocale.languageCode == 'en';
}