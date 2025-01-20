import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_wizz/main.dart';
import 'package:card_wizz/services/storage_service.dart';
import 'package:card_wizz/providers/app_state.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set up SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppState(storageService)),
          ],
          child: const CardWizzApp(),
        ),
      ),
    );

    // Verify that the app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
