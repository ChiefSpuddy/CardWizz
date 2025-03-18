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

/// A widget that dismisses the keyboard when tapped outside of input fields
class DismissKeyboardOnTap extends StatelessWidget {
  final Widget child;
  
  const DismissKeyboardOnTap({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => KeyboardUtils.dismissKeyboard(context),
      behavior: HitTestBehavior.translucent, // Important: allows taps to pass through empty areas
      child: child,
    );
  }
}
