import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import '../screens/card_details_screen.dart';
import '../services/logging_service.dart';

/// A helper class that provides consistent card navigation throughout the app.
class CardNavigationHelper {
  /// Navigates to card details screen with consistent behavior across the app.
  static void navigateToCardDetails(
    BuildContext context, 
    TcgCard card, 
    {String heroContext = 'default'}
  ) {
    LoggingService.debug('CardNavigationHelper: Navigating to details for ${card.name}');
    
    // Create the destination screen
    final detailsScreen = CardDetailsScreen(
      card: card,
      heroContext: heroContext,
    );
    
    // CRITICAL FIX: Use Navigator.of().push() with rootNavigator:true 
    // This ensures we're pushing to the root navigator, bypassing any nested navigators
    // that might be causing the back navigation issue
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        // Use PageRouteBuilder for more control over the transition
        pageBuilder: (context, animation, secondaryAnimation) => detailsScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Use a simple fade + slide transition
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        // Force maintain state to prevent premature disposal
        maintainState: true,
        // Ensure nested navigation contexts are properly handled
        fullscreenDialog: false,
        opaque: true,
      ),
    );
  }
}
