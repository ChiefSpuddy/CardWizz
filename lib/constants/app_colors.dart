import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Add this import for SystemUiOverlayStyle

class AppColors {
  // Primary colors - keeping the same vibrant blue palette from sign in page
  static const Color primary = Color(0xFF3D5AFE);       // Main blue
  static const Color secondary = Color(0xFF00B0FF);     // Lighter blue
  static const Color tertiary = Color(0xFF673AB7);      // Purple accent
  
  // Dark mode accent colors
  static const Color darkAccentPrimary = Color(0xFF82B1FF);
  static const Color darkAccentSecondary = Color(0xFF00E5FF);
  
  // Background colors - pure white for light mode to avoid pink tint
  static const Color background = Color(0xFFFFFFFF);    // Pure white background
  static const Color darkBackground = Color(0xFF121212);
  
  // Card backgrounds
  static const Color cardBackground = Color(0xFFFAFAFA);  // Very slight off-white for cards
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  
  // Text colors - match sign-in page text colors
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
  
  // UI accent colors - match the ones used in sign-in page
  static const Color accentLight = Color(0xFF64FFDA);
  static const Color accentDark = Color(0xFF00B686);
  
  // Divider colors
  static const Color divider = Color(0xFFEEEEEE);  // Lighter divider for light mode
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
          color: Colors.black.withOpacity(0.08),  // More subtle shadow for light mode
          blurRadius: elevation * 3,
          spreadRadius: elevation / 4,
          offset: Offset(0, elevation),
        ),
      ];
    }
  }
  
  // Card decorations - match sign-in page card style
  static final lightModeCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFFEEEEEE), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
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
  
  // Gradient backgrounds like sign-in page
  static LinearGradient getLightModeGradient(double animationValue) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        background.withAlpha((0.8 * 255).round()),
        Color.lerp(background, primary, 0.03) ?? background,
        Color.lerp(background, primary, 0.07) ?? background,
        background.withAlpha((0.8 * 255).round()),
      ],
      stops: [
        0,
        0.3 + (animationValue * 0.2),
        0.6 + (animationValue * 0.2),
        1,
      ],
    );
  }
  
  static LinearGradient getDarkModeGradient(double animationValue) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        darkBackground.withAlpha((0.8 * 255).round()),
        Color.lerp(darkBackground, darkAccentPrimary, 0.05) ?? darkBackground,
        Color.lerp(darkBackground, darkAccentPrimary, 0.1) ?? darkBackground,
        darkBackground.withAlpha((0.8 * 255).round()),
      ],
      stops: [
        0,
        0.3 + (animationValue * 0.2),
        0.6 + (animationValue * 0.2),
        1,
      ],
    );
  }
  
  // Helper method to get ThemeData
  static ThemeData getThemeData(bool isDarkMode) {
    if (isDarkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: darkAccentPrimary,
        colorScheme: const ColorScheme.dark(
          primary: darkAccentPrimary,
          secondary: darkAccentSecondary,
          tertiary: tertiary,  // Add tertiary color
          surface: darkBackground,
          background: darkBackground,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: textDarkPrimary,
          onSurface: textDarkPrimary,
        ),
        scaffoldBackgroundColor: darkBackground,
        cardColor: darkCardBackground,
        dividerColor: darkDivider,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: darkAccentPrimary,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          backgroundColor: darkCardBackground,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
          color: darkCardBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: primary,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,  // Add tertiary color
          surface: Colors.white,
          background: background,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: textPrimary,
          onSurface: textPrimary,
        ),
        scaffoldBackgroundColor: background,
        cardColor: cardBackground,
        dividerColor: divider,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: primary,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.white,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
