import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import '../utils/card_details_router.dart';

// This class is now just a router to the appropriate screen type
class CardDetailsScreen extends StatelessWidget {
  final TcgCard card;
  final String heroContext;
  final bool isFromBinder;
  final bool isFromCollection;

  const CardDetailsScreen({
    super.key,
    required this.card,
    this.heroContext = 'details',
    this.isFromBinder = false,
    this.isFromCollection = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use the router to get the appropriate screen
    return CardDetailsRouter.getDetailsScreen(
      card: card,
      heroContext: heroContext,
      isFromBinder: isFromBinder,
      isFromCollection: isFromCollection,
    );
  }
}
