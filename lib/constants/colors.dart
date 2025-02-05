import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const primary = Color(0xFF6366F1);    // Soft indigo
  static const secondary = Color(0xFF818CF8);  // Light indigo
  static const background = Color(0xFFF8FAFC); // Cool gray
  static const surface = Colors.white;
  static const error = Color(0xFFF43F5E);      // Soft rose
  static const text = Color(0xFF1E293B);       // Slate
  static const textSecondary = Color(0xFF64748B);
  static const onSurface = Color(0xFF1E293B);  // Add this
  static const onBackground = Color(0xFF1E293B);  // Add this
  static const onPrimary = Colors.white;  // Add this
  static const onSecondary = Colors.white;  // Add this

  // Add Pokemon tile colors
  static const pokemonTileCollected = Color(0xFFE8F5E9);  // Light green for light mode
  static const pokemonTileUncollected = Colors.white;
  
  // Dark mode Pokemon tile colors
  static final pokemonTileCollectedDark = Color(0xFF1B3726);  // Dark green for dark mode
  static final pokemonTileUncollectedDark = Color(0xFF2A2A2A);  // Dark surface color

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF1F5F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark mode specific colors
  static final darkSurface = Color(0xFF1E1E1E);
  static final darkBackground = Color(0xFF121212);
  static final darkPrimaryContainer = primary.withOpacity(0.12);
  static final darkSecondaryContainer = secondary.withOpacity(0.12);

  // Dark mode gradients
  static final darkCardGradient = LinearGradient(
    colors: [darkSurface, darkBackground],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final darkAccentGradient = LinearGradient(
    colors: [primary.withOpacity(0.3), secondary.withOpacity(0.3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Add this extension method at the bottom of the file
extension GradientScale on LinearGradient {
  LinearGradient scale(double factor) {
    return LinearGradient(
      colors: colors.map((color) => Color.lerp(color, Colors.white, 1 - factor)!).toList(),
      begin: begin,
      end: end,
      stops: stops,
      tileMode: tileMode,
    );
  }
}