import 'package:flutter/material.dart';

/// A service that provides access to the global navigator key for the app.
/// This allows access to the navigator state from anywhere in the app.
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Check if we have a valid context
  static bool get hasContext => navigatorKey.currentContext != null;
  
  // Get the current context from the navigator
  static BuildContext? get currentContext => navigatorKey.currentContext;
  
  // Get the current state from the navigator
  static NavigatorState? get state => navigatorKey.currentState;
  
  // Navigate to a named route
  static Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }
  
  // Navigate to a named route and remove all previous routes
  static Future<dynamic>? navigateToAndRemoveUntil(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName, 
      (route) => false, 
      arguments: arguments
    );
  }
  
  // Navigate back
  static void goBack() {
    return navigatorKey.currentState?.pop();
  }
}
