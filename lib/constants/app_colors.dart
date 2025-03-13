import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Add this import for SystemUiOverlayStyle

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF3D5AFE);
  static const Color secondary = Color(0xFF00B0FF);
  static const Color tertiary = Color(0xFF673AB7);
  
  // Dark mode accent colors
  static const Color darkAccentPrimary = Color(0xFF82B1FF);
  static const Color darkAccentSecondary = Color(0xFF00E5FF);
  
  // Background colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color darkBackground = Color(0xFF121212);
  
  // Card backgrounds
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDarkPrimary = Color(0xFFE0E0E0);
  static const Color textDarkSecondary = Color(0xFFB0B0B0);
  
  // Search bar colors
  static const Color searchBarLight = Color(0xFFF1F1F1);
  static const Color searchBarDark = Color(0xFF2A2A2A);
  
  // Pokemon and MTG specific colors
  static const Color primaryPokemon = Color(0xFFE53935);
  static const Color primaryMtg = Color(0xFF5D4037);
  
  // UI accent colors
  static const Color accentLight = Color(0xFF64FFDA);
  static const Color accentDark = Color(0xFF00B686);
  
  // Divider colors
  static const Color divider = Color(0xFFDBDBDB);
  static const Color darkDivider = Color(0xFF333333);
  
  // Get shadow for cards based on theme
  static List<BoxShadow> getCardShadow({double elevation = 2.0, bool isDark = false}) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: elevation * 2,
          spreadRadius: elevation / 2,
          offset: Offset(0, elevation),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 3,
          spreadRadius: elevation / 4,
          offset: Offset(0, elevation),
        ),
      ];
    }
  }
  
  // Card decorations
  static final darkModeCardDecoration = BoxDecoration(
    color: Color(0xFF1D1D1D),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFF2C2C2C), width: 1),
  );
  
  static final darkModePremiumCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1A2334),
        Color(0xFF1D1D28),
      ],
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFF3D4663), width: 1),
  );
  
  // Helper method to get ThemeData
  static ThemeData getThemeData(bool isDarkMode) {
    if (isDarkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: darkAccentPrimary,
        colorScheme: const ColorScheme.dark(
          primary: darkAccentPrimary,
          secondary: darkAccentSecondary,
          surface: darkBackground,
          background: darkBackground,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: primary,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: Colors.white,
          background: background,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
      );
    }
  }
}
