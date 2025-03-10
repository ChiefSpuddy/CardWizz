import 'package:flutter/material.dart';
import '../screens/search_screen.dart';

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
}
