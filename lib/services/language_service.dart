import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  String _currentLocale = 'en';
  static const String _localeKey = 'app_locale';

  LanguageService() {
    _loadLocale();
  }

  String get currentLocale => _currentLocale;

  bool get isHindi => _currentLocale == 'hi';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      _currentLocale = savedLocale;
      // Safety: notify after current build cycle to avoid assertion errors during Hot Reload
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> setLocale(String locale) async {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale);
    }
  }

  Future<void> toggleLanguage() async {
    _currentLocale = (_currentLocale == 'en') ? 'hi' : 'en';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, _currentLocale);
  }
}
