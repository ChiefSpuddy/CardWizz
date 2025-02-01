import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/collections_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/analytics_screen.dart';  // Add this import
import 'screens/dex_screen.dart';  // Add this import

class AppRoutes {
  static const String home = '/';
  static const String collection = '/collection';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String analytics = '/analytics';  // Add this route
  static const String dex = '/dex';  // Add this route

  static Map<String, WidgetBuilder> get routes => {
    '/home': (context) => const HomeScreen(), // Your home screen
    collection: (context) => const CollectionsScreen(),
    search: (context) => const SearchScreen(),
    settings: (context) => const SettingsScreen(),
    profile: (context) => const ProfileScreen(),
    analytics: (context) => const AnalyticsScreen(),  // Add this route
    dex: (context) => const DexScreen(),  // Add this route
  };
}
