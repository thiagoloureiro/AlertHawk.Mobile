import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemeMode();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  // Gray color palette matching gray-900
  static const Color _gray900 = Color(0xFF111827); // Background
  static const Color _gray800 = Color(0xFF1F2937); // Cards, surfaces, menus
  static const Color _gray700 = Color(0xFF374151); // Dividers, borders
  static const Color _gray600 = Color(0xFF4B5563); // Secondary elements

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _gray900,
    cardColor: _gray800,
    dividerColor: _gray700,
    dialogBackgroundColor: _gray800,
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
      background: _gray900,
      surfaceContainerHighest: _gray700,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
  );
}
