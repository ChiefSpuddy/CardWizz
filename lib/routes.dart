import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';  // Add this import
import 'screens/collections_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String collection = '/collection';

  static Map<String, Widget Function(BuildContext)> get routes => {
        home: (context) => const HomeScreen(),
        search: (context) => const SearchScreen(),  // Add this route
        settings: (context) => const Placeholder(),
        collection: (context) => const CollectionsScreen(),
      };
}
