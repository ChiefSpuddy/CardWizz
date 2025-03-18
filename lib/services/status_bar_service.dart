import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/logging_service.dart';

/// Service that enforces correct status bar styles throughout the app lifecycle
class StatusBarService {
  static final StatusBarService _instance = StatusBarService._internal();
  static StatusBarService get instance => _instance;
  
  Timer? _enforcementTimer;
  bool _isEnforcing = false;

  StatusBarService._internal();

  /// Start enforcing status bar style across the app
  void startEnforcing() {
    if (_isEnforcing) return;
    _isEnforcing = true;
    
    // Apply immediately
    enforceStatusBarStyle();
    
    // Set timer to periodically enforce status bar style
    // This is necessary because some system actions may override our style
    _enforcementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      enforceStatusBarStyle();
    });
    
    LoggingService.debug('StatusBarService: Started enforcing status bar style');
  }
  
  /// Stop enforcing status bar style
  void stopEnforcing() {
    _enforcementTimer?.cancel();
    _enforcementTimer = null;
    _isEnforcing = false;
    LoggingService.debug('StatusBarService: Stopped enforcing status bar style');
  }

  /// Enforce the correct status bar style based on current brightness
  void enforceStatusBarStyle() {
    final window = WidgetsBinding.instance.window;
    final brightness = window.platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    LoggingService.debug('StatusBarService: Enforcing status bar style - isDark: $isDark');
    
    // Force status bar style with maximum priority
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light, // White text in dark mode
              statusBarBrightness: Brightness.dark,      // Dark background (iOS)
              systemNavigationBarColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,  // Black text in light mode
              statusBarBrightness: Brightness.light,     // Light background (iOS)
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );
  }
  
  /// Apply status bar style once immediately (useful for transitions)
  void applyStatusBarStyle(bool isDark) {
    LoggingService.debug('StatusBarService: Applying one-time status bar style - isDark: $isDark');
    
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light, // White text in dark mode
              statusBarBrightness: Brightness.dark,     // Dark background (iOS)
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,  // Black text in light mode
              statusBarBrightness: Brightness.light,    // Light background (iOS) 
            ),
    );
  }
}
