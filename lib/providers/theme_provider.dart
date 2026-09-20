import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

enum AppThemeMode {
  light,
  dark,
  githubDark,
  monokai,
}

extension AppThemeModeExtension on AppThemeMode {
  String get name {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.githubDark:
        return 'githubDark';
      case AppThemeMode.monokai:
        return 'monokai';
    }
  }

  static AppThemeMode fromName(String? name) {
    switch (name) {
      case 'dark':
        return AppThemeMode.dark;
      case 'githubDark':
        return AppThemeMode.githubDark;
      case 'monokai':
        return AppThemeMode.monokai;
      default:
        return AppThemeMode.light;
    }
  }
}

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  AppThemeMode _themeMode = AppThemeMode.light;

  ThemeProvider() {
    _loadThemeMode();
  }

  AppThemeMode get themeMode => _themeMode;

  /// True for dark, GitHub Dark, and Monokai (for UI that only needs light vs dark).
  bool get isDarkMode =>
      _themeMode != AppThemeMode.light;

  /// Display name for the current theme (e.g. for tooltips).
  String get themeDisplayName {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.githubDark:
        return 'GitHub Dark';
      case AppThemeMode.monokai:
        return 'Monokai';
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_themeKey);
    _themeMode = AppThemeModeExtension.fromName(name);
    notifyListeners();
  }

  /// Cycles: light → dark → GitHub Dark → Monokai → light. Persists and notifies.
  Future<void> cycleTheme() async {
    switch (_themeMode) {
      case AppThemeMode.light:
        _themeMode = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        _themeMode = AppThemeMode.githubDark;
        break;
      case AppThemeMode.githubDark:
        _themeMode = AppThemeMode.monokai;
        break;
      case AppThemeMode.monokai:
        _themeMode = AppThemeMode.light;
        break;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.name);
    notifyListeners();
  }

  /// Set a specific theme. Persists and notifies.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeMode.name);
    notifyListeners();
  }

  /// Kept for compatibility; behaves as cycleTheme.
  Future<void> toggleTheme() async => cycleTheme();

  ThemeData get theme {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.light;
      case AppThemeMode.dark:
        return AppTheme.dark;
      case AppThemeMode.githubDark:
        return AppTheme.githubDark;
      case AppThemeMode.monokai:
        return AppTheme.monokai;
    }
  }
}
