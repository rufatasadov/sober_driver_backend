import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en'; // Default to English
  static const String _languageKey = 'selected_language';

  String get currentLanguage => _currentLanguage;

  String getString(String key) {
    return AppLocalizations.getString(key, _currentLanguage);
  }

  Future<void> loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null &&
          AppLocalizations.getSupportedLanguages().contains(savedLanguage)) {
        _currentLanguage = savedLanguage;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (AppLocalizations.getSupportedLanguages().contains(languageCode)) {
      _currentLanguage = languageCode;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_languageKey, languageCode);
      } catch (e) {
        print('Error saving language: $e');
      }
    }
  }

  List<Map<String, String>> getLanguageOptions() {
    return AppLocalizations.getSupportedLanguages()
        .map(
          (code) => {
            'code': code,
            'name': AppLocalizations.getLanguageName(code),
          },
        )
        .toList();
  }
}
