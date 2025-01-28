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