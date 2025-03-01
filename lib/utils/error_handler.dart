import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A utility class for handling and logging errors throughout the app
class ErrorHandler {
  /// Log an error with optional stack trace and context
  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    final errorMessage = error != null ? ': $error' : '';
    debugPrint('❌ ERROR: $message$errorMessage');
    
    if (stackTrace != null && kDebugMode) {
      debugPrint('📚 STACK: $stackTrace');
    }
  }

  /// Display a snackbar with an error message
  static void showErrorSnackBar(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: const Duration(seconds: 4),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: Colors.white,
            )
          : null,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Handle image loading errors
  static Widget imageErrorWidget(BuildContext context, String url, dynamic error) {
    logError('Failed to load image', '$url - $error');
    
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.grey.shade600,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension for handling errors on Future objects
extension ErrorHandlingFutureExtension<T> on Future<T> {
  /// Handle errors with a default value and optional logging
  Future<T> withDefault(T defaultValue, {String? errorMessage}) {
    return this.catchError((error, stackTrace) {
      if (errorMessage != null) {
        ErrorHandler.logError(errorMessage, error, stackTrace);
      }
      return defaultValue;
    });
  }
}
