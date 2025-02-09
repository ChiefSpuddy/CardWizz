import 'package:flutter/material.dart';
// ...existing imports...
import 'screens/collection_index_screen.dart';  // Add this import, remove dex_screen.dart import

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...existing code...
      routes: {
        // ...existing routes...
        '/dex': (context) => const CollectionIndexScreen(),  // This will now use the correct screen
      },
    );
  }
}
