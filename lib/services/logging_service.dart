import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class LoggingService {
  // Global logging control flags
  static const bool _enableDebugLogging = false; // Master switch for all debug logs
  static const bool _enableEbayApiLogs = false; // Specific for eBay API logs
  static const bool _enableStorageLogs = true; // Keep storage logs for now
  
  // Additional flags for specific features
  static const bool _enablePriceCalculationLogs = false;
  static const bool _enableNetworkRequestLogs = false;
  static const bool _enablePerformanceLogs = false;
  
  // Log a message with a specific level
  static void log(String message, {
    LogLevel level = LogLevel.debug,
    String tag = 'App',
  }) {
    // Early return if debug logs are disabled and this is a debug message
    if (!_enableDebugLogging && level == LogLevel.debug) return;
    
    // Category-specific filtering
    if (tag == 'eBay' && !_enableEbayApiLogs) return;
    if (tag == 'Storage' && !_enableStorageLogs) return;
    if (tag == 'Price' && !_enablePriceCalculationLogs) return;
    if (tag == 'Network' && !_enableNetworkRequestLogs) return;
    if (tag == 'Performance' && !_enablePerformanceLogs) return;
    
    // Format the message with an emoji prefix
    final emoji = _getEmojiForLevel(level);
    final formattedMessage = '$emoji $tag: $message';
    
    // Use Flutter's developer log for better formatting in debug console
    developer.log(
      formattedMessage,
      name: level.name.toUpperCase(),
      time: DateTime.now(),
    );
  }
  
  // Debug level convenience method
  static void debug(String message, {String tag = 'App'}) {
    log(message, level: LogLevel.debug, tag: tag);
  }
  
  // Info level convenience method
  static void info(String message, {String tag = 'App'}) {
    log(message, level: LogLevel.info, tag: tag);
  }
  
  // Warning level convenience method
  static void warning(String message, {String tag = 'App'}) {
    log(message, level: LogLevel.warning, tag: tag);
  }
  
  // Error level convenience method
  static void error(String message, {String tag = 'App'}) {
    log(message, level: LogLevel.error, tag: tag);
  }
  
  // Helper function to get emoji for log level
  static String _getEmojiForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}
