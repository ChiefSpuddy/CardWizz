import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState get navigator => navigatorKey.currentState!;
  
  static BuildContext? get currentContext => navigatorKey.currentContext;
  
  static bool get hasContext => currentContext != null;
}
