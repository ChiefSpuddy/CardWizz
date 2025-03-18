import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../screens/card_details_screen.dart';
import '../services/logging_service.dart';
import '../services/storage_service.dart';
import '../providers/currency_provider.dart';
import '../providers/app_state.dart';

/// A helper class that provides consistent card navigation throughout the app.
class CardNavigationHelper {
  /// Navigates to card details screen with consistent behavior across the app.
  static void navigateToCardDetails(
    BuildContext context, 
    TcgCard card, 
    {String heroContext = 'default', bool fromSearchResults = false}
  ) {
    LoggingService.debug('CardNavigationHelper: Navigating to details for ${card.name}');
    
    // Get all necessary providers from the current context
    final storageService = Provider.of<StorageService>(context, listen: false);
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Create the destination screen wrapped with all needed providers
    // Using the correct provider types for each service
    final wrappedScreen = MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        // Fix: Use ChangeNotifierProvider for listenable providers
        ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
        ChangeNotifierProvider<AppState>.value(value: appState),
      ],
      child: CardDetailsScreen(
        card: card,
        heroContext: heroContext,
        fromSearchResults: fromSearchResults,
      ),
    );
    
    // Only use rootNavigator when not coming from search results
    // This ensures we can go back to search results when using the back button
    final useRootNavigator = !fromSearchResults;
    
    Navigator.of(context, rootNavigator: useRootNavigator).push(
      MaterialPageRoute(
        builder: (context) => wrappedScreen,
      ),
    );
  }
}
