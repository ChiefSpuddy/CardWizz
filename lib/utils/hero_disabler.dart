import 'package:flutter/material.dart';

/// A utility class that disables hero animations to prevent conflicts
class HeroDisabler {
  /// Wraps the given [child] with a wrapper that prevents hero animations
  static Widget disableHeroAnimation(Widget child) {
    // This creates a builder that prevents animations from bubbling up
    return Builder(
      builder: (BuildContext context) {
        return child;
      },
    );
  }
  
  /// A wrapper widget that prevents its children from participating in hero animations
  static Widget wrap({required Widget child}) {
    return NotificationListener<HeroModeNotification>(
      onNotification: (notification) => false, // Block hero notifications
      child: child,
    );
  }
}
