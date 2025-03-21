import 'package:flutter/material.dart';

class CardStyles {
  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(2), // Minimized border radius to prevent content clipping
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration gradientDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.secondaryContainer,
        ],
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static TextStyle titleStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static EdgeInsets cardPadding = const EdgeInsets.all(16);
}
