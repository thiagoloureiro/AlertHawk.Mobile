import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

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
        return _lightTheme;
      case AppThemeMode.dark:
        return _darkTheme;
      case AppThemeMode.githubDark:
        return _githubDarkTheme;
      case AppThemeMode.monokai:
        return _monokaiTheme;
    }
  }

  // --- Light theme ---
  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  );

  // --- Dark theme (existing gray palette) ---
  static const Color _gray900 = Color(0xFF111827);
  static const Color _gray800 = Color(0xFF1F2937);
  static const Color _gray700 = Color(0xFF374151);

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _gray900,
    cardColor: _gray800,
    dividerColor: _gray700,
    popupMenuTheme: PopupMenuThemeData(
      color: _gray800,
    ),
    cardTheme: CardThemeData(
      color: _gray800,
      elevation: 2,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      surface: _gray800,
      background: _gray900,
      surfaceContainerHighest: _gray700,
    ).copyWith(
      surface: _gray800,
      surfaceContainerHighest: _gray700,
      onSurface: Colors.white,
    ),
    dialogTheme: DialogThemeData(backgroundColor: _gray800),
  );

  // --- GitHub Dark ---
  static const Color _ghBg = Color(0xFF0D1117);
  static const Color _ghSurface = Color(0xFF161B22);
  static const Color _ghBorder = Color(0xFF30363D);
  static const Color _ghText = Color(0xFFC9D1D9);
  static const Color _ghAccent = Color(0xFF58A6FF);

  static final _githubDarkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _ghBg,
    cardColor: _ghSurface,
    dividerColor: _ghBorder,
    popupMenuTheme: PopupMenuThemeData(
      color: _ghSurface,
    ),
    cardTheme: CardThemeData(
      color: _ghSurface,
      elevation: 2,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.apply(
            bodyColor: _ghText,
            displayColor: _ghText,
          ),
    ),
    colorScheme: ColorScheme.dark(
      primary: _ghAccent,
      onPrimary: _ghBg,
      surface: _ghSurface,
      onSurface: _ghText,
      error: const Color(0xFFF85149),
      onError: Colors.white,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _ghSurface,
      onSurface: _ghText,
      surfaceContainerHighest: _ghBorder,
    ),
    dialogTheme: DialogThemeData(backgroundColor: _ghSurface),
  );

  // --- Monokai ---
  static const Color _monoBg = Color(0xFF272822);
  static const Color _monoSurface = Color(0xFF3E3D32);
  static const Color _monoBorder = Color(0xFF49483E);
  static const Color _monoFg = Color(0xFFF8F8F2);
  static const Color _monoAccent = Color(0xFF66D9EF);

  static final _monokaiTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _monoBg,
    cardColor: _monoSurface,
    dividerColor: _monoBorder,
    popupMenuTheme: PopupMenuThemeData(
      color: _monoSurface,
    ),
    cardTheme: CardThemeData(
      color: _monoSurface,
      elevation: 2,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.apply(
            bodyColor: _monoFg,
            displayColor: _monoFg,
          ),
    ),
    colorScheme: ColorScheme.dark(
      primary: _monoAccent,
      onPrimary: _monoBg,
      surface: _monoSurface,
      onSurface: _monoFg,
      error: const Color(0xFFF92672),
      onError: Colors.white,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _monoSurface,
      onSurface: _monoFg,
      surfaceContainerHighest: _monoBorder,
    ),
    dialogTheme: DialogThemeData(backgroundColor: _monoSurface),
  );
}
