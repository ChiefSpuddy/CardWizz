import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  
  static bool get hasContext => navigatorKey.currentContext != null;
  
  static BuildContext? get currentContext => navigatorKey.currentContext;
}
