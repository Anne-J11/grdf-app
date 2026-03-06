// lib/core/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get modeLabel {
    switch (_mode) {
      case AppThemeMode.light:
        return 'Clair';
      case AppThemeMode.dark:
        return 'Sombre';
      case AppThemeMode.system:
        return 'Système';
    }
  }

  IconData get modeIcon {
    switch (_mode) {
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
      case AppThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'system';
    switch (saved) {
      case 'light':
        _mode = AppThemeMode.light;
        break;
      case 'dark':
        _mode = AppThemeMode.dark;
        break;
      default:
        _mode = AppThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case AppThemeMode.light:
        await prefs.setString('theme_mode', 'light');
        break;
      case AppThemeMode.dark:
        await prefs.setString('theme_mode', 'dark');
        break;
      case AppThemeMode.system:
        await prefs.setString('theme_mode', 'system');
        break;
    }
  }

  // ── Thème clair ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const primary = Color(0xFF33A1C9);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: Colors.white,
      dividerColor: Color(0xFFE0E0E0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Thème sombre ─────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const primary = Color(0xFF4DB8D9);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: const Color(0xFF2C2C2C),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}