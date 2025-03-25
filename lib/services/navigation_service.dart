import 'package:flutter/material.dart';
import '../screens/search_screen.dart';
import '../screens/root_navigator.dart';
import '../services/logging_service.dart';

/// A service that provides access to the global navigator key for the app.
/// This allows access to the navigator state from anywhere in the app.
class NavigationService {
  // IMPORTANT: Use a private constructor and singleton pattern to ensure only one instance
  NavigationService._();
  static final NavigationService _instance = NavigationService._();
  static NavigationService get instance => _instance;
  
  // Create a single global key that's used throughout the app
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'AppNavigator');
  
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
    navigatorKey.currentState?.pop();
  }
  
  /// Improved method to switch tabs that first tries to find RootNavigatorState
  static void switchToTab(int tabIndex) {
    LoggingService.debug('NavigationService: Switching to tab $tabIndex');
    
    // First try to find a RootNavigatorState in the current context
    final context = navigatorKey.currentContext;
    if (context != null) {
      final rootNavigator = context.findRootAncestorStateOfType<RootNavigatorState>();
      if (rootNavigator != null) {
        rootNavigator.setSelectedIndex(tabIndex);
        LoggingService.debug('NavigationService: Used RootNavigatorState directly');
        return;
      }
    }
    
    // Fallback to the route-based approach
    if (navigatorKey.currentState != null) {
      try {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/',
          (route) => false,
          arguments: {'initialTab': tabIndex}
        );
        LoggingService.debug('NavigationService: Used route-based approach');
        return;
      } catch (e) {
        LoggingService.debug('NavigationService: Error navigating to tab: $e');
      }
    }
    
    // Last resort fallback
    LoggingService.debug('NavigationService: No navigation options worked');
  }
}
