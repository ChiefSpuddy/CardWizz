import 'package:flutter/material.dart';
import '../screens/search_screen.dart';

// ...existing code...

  void _onItemTapped(BuildContext context, int index) {
    if (index == 1) { // Search tab
      if (ModalRoute.of(context)?.settings.name == '/search') {
        // Use the static method from SearchScreen
        SearchScreen.clearSearchState(context);
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/search',
        (route) => false,
      );
    } else {
      // ...existing navigation logic...
    }
  }

// ...existing code...
