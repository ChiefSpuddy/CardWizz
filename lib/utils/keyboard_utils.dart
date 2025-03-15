import 'package:flutter/material.dart';

class KeyboardUtils {
  /// Dismisses the keyboard when called
  static void dismissKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
  
  /// Creates a gesture detector that dismisses keyboard when tapped/dragged
  static Widget createDismissibleKeyboardContainer({
    required Widget child,
    bool enableTapDismiss = true,
    bool enableDragDismiss = true,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: enableTapDismiss ? () => dismissKeyboard(context) : null,
          onVerticalDragEnd: enableDragDismiss 
              ? (DragEndDetails details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
                    dismissKeyboard(context);
                  }
                }
              : null,
          behavior: HitTestBehavior.translucent, // Critical to detect taps anywhere
          child: child,
        );
      },
    );
  }
}
