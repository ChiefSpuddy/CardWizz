import 'package:flutter/material.dart';
import '../screens/search_screen.dart';
import '../screens/root_navigator.dart';  // Import RootNavigator
import '../services/logging_service.dart'; // Import Logging

/// A service that provides access to the global navigator key for the app.
/// This allows access to the navigator state from anywhere in the app.
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Keep the utility methods
  static bool get hasContext => navigatorKey.currentContext != null;
  static BuildContext? get currentContext => navigatorKey.currentContext;
  static NavigatorState? get state => navigatorKey.currentState;
  
  static Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }
  
  static Future<dynamic>? navigateToAndRemoveUntil(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName, 
      (route) => false, 
      arguments: arguments
    );
  }
  
  static void goBack() {
    return navigatorKey.currentState?.pop();
  }
  
  /// Switches to a specific tab in the bottom navigation bar
  ///
  /// @param tabIndex The index of the tab to switch to (0-4)
  static void switchToTab(int tabIndex) {
    LoggingService.debug('NavigationService: Switching to tab $tabIndex');
    
    try {
      // First try: Find RootNavigator state and use setSelectedIndex
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Find the RootNavigatorState directly
        final rootState = context.findAncestorStateOfType<RootNavigatorState>();
        if (rootState != null) {
          LoggingService.debug('NavigationService: Found RootNavigatorState, setting tab index');
          rootState.setSelectedIndex(tabIndex);
          return;
        }
      }
    } catch (e) {
      LoggingService.debug('NavigationService: First tab switch attempt failed: $e');
    }
    
    try {
      // Second try: Navigate to root with initial tab parameter
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/', 
        (route) => false,
        arguments: {'initialTab': tabIndex}
      );
    } catch (e) {
      LoggingService.debug('NavigationService: Second tab switch attempt failed: $e');
      
      // Last resort: Use a post-frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final context = navigatorKey.currentContext;
          if (context != null) {
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
              arguments: {'initialTab': tabIndex}
            );
          }
        } catch (e) {
          LoggingService.debug('NavigationService: Post-frame tab switch failed: $e');
        }
      });
    }
  }
}
