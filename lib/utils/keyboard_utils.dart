import 'package:flutter/material.dart';

/// Utility methods for keyboard management
class KeyboardUtils {
  /// Dismiss the keyboard if it's currently shown
  static void dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}

/// A widget that dismisses the keyboard when tapped outside of a text field.
class DismissKeyboardOnTap extends StatelessWidget {
  final Widget child;

  const DismissKeyboardOnTap({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // This will ensure all textfields lose focus when tapping outside
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      // Set behavior to opaque and remove the exclusion of child taps
      behavior: HitTestBehavior.translucent, // Changed from opaque to translucent
      child: child,
    );
  }
}
