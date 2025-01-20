import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Map<String, Widget Function(BuildContext)> get routes => {
        home: (context) => const HomeScreen(),
        profile: (context) => const Placeholder(),
        settings: (context) => const Placeholder(),
      };
}
