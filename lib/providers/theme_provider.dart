import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'app_theme';

  late ThemeMode _themeMode;
  bool _isInitialized = false;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark || 
    (_themeMode == ThemeMode.system && 
      SchedulerBinding.instance.window.platformBrightness == Brightness.dark);

  // Returns the current theme data based on dark mode status
  ThemeData get currentThemeData => AppColors.getThemeData(isDarkMode);

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePreferenceKey);
    
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    } else {
      _themeMode = ThemeMode.system;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, mode.index);
  }
  
  // Helper methods to toggle theme
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
  
  void setDarkMode() => setThemeMode(ThemeMode.dark);
  void setLightMode() => setThemeMode(ThemeMode.light);
  void setSystemMode() => setThemeMode(ThemeMode.system);
}
