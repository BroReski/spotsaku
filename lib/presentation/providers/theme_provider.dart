/// Theme (dark / light) state, persisted across launches via
/// `shared_preferences`.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Loads the saved preference. Call once on app start.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(AppPrefs.isDarkMode) ?? false;
    notifyListeners();
  }

  /// Toggles between dark and light mode and persists the choice.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPrefs.isDarkMode, _isDarkMode);
  }
}
