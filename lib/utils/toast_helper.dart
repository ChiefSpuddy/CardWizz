import 'package:flutter/material.dart';
import '../widgets/styled_toast.dart';

/// A helper class to standardize toast notifications throughout the app
class ToastHelper {
  /// Shows a success toast from the bottom of the screen
  static void showSuccess(BuildContext context, String title, String message) {
    showToast(
      context: context,
      title: title,
      subtitle: message,
      icon: Icons.check_circle,
      fromBottom: true,
      bottomOffset: 80,
      duration: const Duration(seconds: 2),
    );
  }

  /// Shows an error toast from the bottom of the screen
  static void showError(BuildContext context, String title, String error) {
    showToast(
      context: context,
      title: title,
      subtitle: error,
      icon: Icons.error_outline,
      isError: true,
      bottomOffset: 80,
      duration: const Duration(seconds: 3),
    );
  }

  /// Shows a card added confirmation from the bottom of the screen
  static void showCardAdded(BuildContext context, String cardName) {
    showToast(
      context: context,
      title: 'Card Added',
      subtitle: '$cardName added to collection',
      icon: Icons.check_circle,
      bottomOffset: 80,
      duration: const Duration(seconds: 2),
    );
  }
}
