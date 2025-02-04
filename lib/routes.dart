import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/collections_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/dex_screen.dart';
import 'screens/scanner_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String collection = '/collection';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String analytics = '/analytics';
  static const String dex = '/dex';
  static const String scanner = '/scanner';

  static Map<String, WidgetBuilder> get routes => {
    '/': (context) => const HomeScreen(),
    collection: (context) => const CollectionsScreen(),
    analytics: (context) => const AnalyticsScreen(),
    search: (context) => const SearchScreen(),
    settings: (context) => const SettingsScreen(),
    profile: (context) => const ProfileScreen(),
    dex: (context) => const DexScreen(),
    scanner: (context) => const ScannerScreen(),
  };
}
