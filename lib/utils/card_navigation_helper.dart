import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import '../screens/card_details_screen.dart';
import '../services/logging_service.dart';

/// A helper class that provides consistent card navigation throughout the app.
class CardNavigationHelper {
  /// Navigates to card details screen with consistent behavior across the app.
  /// This bypasses named routes which can sometimes have issues with nested navigators.
  static void navigateToCardDetails(
    BuildContext context, 
    TcgCard card, 
    {String heroContext = 'default'}
  ) {
    LoggingService.debug('CardNavigationHelper: Navigating to details for ${card.name} with heroContext: $heroContext');
    
    // Create the destination screen first to ensure it's initialized properly
    final detailsScreen = CardDetailsScreen(
      card: card,
      heroContext: heroContext,
    );
    
    // Push with maximum reliability using basic MaterialPageRoute
    // This is the most direct and reliable navigation method
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => detailsScreen,
      ),
    );
  }
}
