import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF0A0E27);
  static const Color darkSecondary = Color(0xFF1A1F3A);
  static const Color darkTertiary = Color(0xFF2D3561);
  static const Color darkCard = Color(0xFF1E2746);
  static const Color darkInput = Color(0xFF2A3441);
  static const Color darkAccent = Color(0xFF6C63FF);
  static const Color darkAccentSecondary = Color(0xFF4834D4);

  // Light Theme Colors
  static const Color lightPrimary = Color(0xFFF8F9FA);
  static const Color lightSecondary = Color(0xFFFFFFFF);
  static const Color lightTertiary = Color(0xFFF1F3F4);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFF5F5F5);
  static const Color lightAccent = Color(0xFF6C63FF);
  static const Color lightAccentSecondary = Color(0xFF4834D4);

  // Get current theme colors
  Color get primaryColor => _isDarkMode ? darkPrimary : lightPrimary;
  Color get secondaryColor => _isDarkMode ? darkSecondary : lightSecondary;
  Color get tertiaryColor => _isDarkMode ? darkTertiary : lightTertiary;
  Color get cardColor => _isDarkMode ? darkCard : lightCard;
  Color get inputColor => _isDarkMode ? darkInput : lightInput;
  Color get accentColor => _isDarkMode ? darkAccent : lightAccent;
  Color get accentSecondaryColor => _isDarkMode ? darkAccentSecondary : lightAccentSecondary;
  Color get textColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get textSecondaryColor => _isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54;
  Color get borderColor => _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

  // Get gradient colors
  List<Color> get backgroundGradient => _isDarkMode 
    ? [darkPrimary, darkSecondary, darkTertiary]
    : [lightPrimary, lightSecondary, lightTertiary];

  List<Color> get accentGradient => [accentColor, accentSecondaryColor];
}