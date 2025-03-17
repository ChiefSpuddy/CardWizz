import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/tcg_card.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import '../../providers/app_state.dart';
import '../../widgets/card_grid_item.dart';
// Remove unified notification system import as we'll delegate notification to parent

class CardSearchGrid extends StatelessWidget {
  final List<TcgCard> cards;
  final Map<String, Image> imageCache;
  final Function(String) loadImage;
  final Set<String> loadingRequestedUrls;
  final Function(TcgCard) onCardTap;
  final Function(TcgCard) onAddToCollection;

  const CardSearchGrid({
    Key? key,
    required this.cards,
    required this.imageCache,
    required this.loadImage,
    required this.loadingRequestedUrls,
    required this.onCardTap,
    required this.onAddToCollection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65, 
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildCardItem(context, cards[index], index),
          childCount: cards.length,
        ),
      ),
    );
  }

  // Add the index parameter to create a unique hero context
  Widget _buildCardItem(BuildContext context, TcgCard card, int index) {
    return Consumer<StorageService>(
      builder: (context, storageService, _) {
        return StreamBuilder<List<dynamic>>(
          stream: storageService.watchCards(),
          builder: (context, snapshot) {
            final myCards = snapshot.data ?? [];
            final myCardIds = myCards.whereType<TcgCard>().map((c) => c.id).toSet();
            final isInCollection = myCardIds.contains(card.id);
            
            // Use CardGridItem with a unique hero context based on index
            return CardGridItem(
              card: card,
              heroContext: 'search_$index', // Use a unique hero context
              onTap: () => onCardTap(card),
              onAddToCollection: () => _handleAddToCollection(context, card, isInCollection),
              isInCollection: isInCollection,
              showPrice: true,
              showName: true,
              highQuality: true,
            );
          },
        );
      },
    );
  }

  void _handleAddToCollection(BuildContext context, TcgCard card, bool isAlreadyInCollection) {
    if (isAlreadyInCollection) return;
    
    // Provide immediate feedback
    HapticFeedback.lightImpact();
    
    // CRITICAL FIX: Just delegate to the parent callback
    // This prevents double notifications
    onAddToCollection(card);
    
    // Remove the following code:
    // final storageService = Provider.of<StorageService>(context, listen: false);
    // storageService.saveCard(card, preventNavigation: true).then((_) {
    //   NotificationManager.success(...);
    //   onAddToCollection(card);  <-- This was calling the callback after showing notification
    // }).catchError((e) {
    //   NotificationManager.error(...);
    // });
  }
}
