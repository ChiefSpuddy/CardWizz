import 'package:flutter/material.dart';

/// Extension on Color to help with the migration from deprecated withOpacity
extension ColorExtension on Color {
  /// Replace deprecated withOpacity with withAlpha
  Color withOpacityValue(double opacity) {
    return Color.fromARGB(
      (opacity * 255).round(),
      red,
      green,
      blue,
    );
  }
}

/// Extension on ColorScheme for easy migration from deprecated values
extension ColorSchemeExtension on ColorScheme {
  /// Use surfaceContainerHighest instead of surfaceVariant
  Color get surfaceContainerHighest => surface.withOpacityValue(0.95);
  
  /// Use onSurface instead of onBackground for backwards compatibility
  Color get onSurface2 => onSurface;
}
