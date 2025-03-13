import 'package:flutter/foundation.dart'; // Add this import for kReleaseMode and debugPrint

/// Logger utility to control debug output throughout the app
class AppLogger {
  /// Set this to false to disable all logging
  static bool enabled = true;
  
  /// Set minimum log level (0=verbose, 1=debug, 2=info, 3=warning, 4=error)
  static int logLevel = 1;
  
  /// Log a verbose message (level 0)
  static void v(String message, {String? tag}) {
    _log(0, message, tag: tag);
  }
  
  /// Log a debug message (level 1)
  static void d(String message, {String? tag}) {
    _log(1, message, tag: tag);
  }
  
  /// Log an info message (level 2)
  static void i(String message, {String? tag}) {
    _log(2, message, tag: tag);
  }
  
  /// Log a warning message (level 3)
  static void w(String message, {String? tag}) {
    _log(3, message, tag: tag);
  }
  
  /// Log an error message (level 4)
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(4, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void _log(int level, String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace
  }) {
    // Skip logging if disabled or below minimum level
    if (!enabled || level < logLevel) return;
    
    // Only log in debug mode by default
    if (kReleaseMode) return;
    
    final prefix = tag != null ? '[$tag] ' : '';
    final levelIndicator = _getLevelPrefix(level);
    
    debugPrint('$levelIndicator$prefix$message');
    
    if (error != null) {
      debugPrint('$levelIndicator$prefix Error: $error');
      if (stackTrace != null) {
        debugPrint('$levelIndicator$prefix StackTrace: $stackTrace');
      }
    }
  }
  
  static String _getLevelPrefix(int level) {
    switch (level) {
      case 0: return '🔍 VERBOSE: ';
      case 1: return '🐛 DEBUG: ';
      case 2: return 'ℹ️ INFO: ';
      case 3: return '⚠️ WARNING: ';
      case 4: return '❌ ERROR: ';
      default: return '';
    }
  }
  
  /// Quick utility to completely disable all app logging
  static void disableLogging() {
    enabled = false;
  }
  
  /// Set logging to show only warnings and errors
  static void quietMode() {
    enabled = true;
    logLevel = 3; // Warnings and errors only
  }
  
  /// Set logging to show all messages
  static void verboseMode() {
    enabled = true;
    logLevel = 0;
  }
}
