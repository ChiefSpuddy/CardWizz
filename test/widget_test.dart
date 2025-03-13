import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Fix imports to use relative paths instead of package paths
import '../lib/main.dart';
import '../lib/services/storage_service.dart';
import '../lib/providers/app_state.dart';

void main() {
  testWidgets('Smoke test - app launches without crashing', (WidgetTester tester) async {
    // Build our app with mocked storage service
    final storageService = StorageService();
    
    // Create app with mocked dependencies
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>(
            create: (context) => AppState(storageService: storageService),
          ),
          Provider<StorageService>.value(value: storageService),
        ],
        child: const CardWizzApp(),
      ),
    );

    // Simple verification that the app rendered something
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
