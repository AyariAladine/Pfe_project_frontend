import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('ar');
  
  Locale get currentLocale => _currentLocale;
  
  LanguageProvider() {
    _loadLanguage();
  }
  
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'ar';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }
  
  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }
  
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isFrench => _currentLocale.languageCode == 'fr';
}
