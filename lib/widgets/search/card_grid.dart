import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/tcg_card.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import '../../providers/app_state.dart';
import '../../widgets/bottom_notification.dart'; // Import BottomNotification
import '../../widgets/card_grid_item.dart';

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
    
    // FIX: Use a more direct approach without any navigation
    try {
      // Provide tactile feedback immediately for responsive feel
      HapticFeedback.mediumImpact();
      
      // Access the services directly without delays
      final appState = Provider.of<AppState>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Don't use .then or async/await here - keep it synchronous
      // But schedule the actual saving outside the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // This runs after the current frame completes
        storageService.saveCard(card).then((_) {
          // Only notify state and show notification after successful save
          appState.notifyCardChange();
          
          if (context.mounted) {
            // Simple notification without overlay or animations
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${card.name} added to collection'))
            );
          }
          // Don't call any callbacks that might cause navigation
        });
      });
    } catch (e) {
      // Show error directly without complex overlay
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }

  // Handle the actual saving in background
  Future<void> _saveCardInBackground(BuildContext context, TcgCard card) async {
    try {
      // Get services
      final appState = Provider.of<AppState>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Save the card without awaiting to avoid UI blockage
      storageService.saveCard(card).then((_) {
        // Notify app state after save completes
        appState.notifyCardChange();
        
        // Show feedback notification
        BottomNotification.show(
          context: context,
          title: 'Added to Collection',
          message: card.name,
          icon: Icons.check_circle,
        );
        
        // Call the callback to update UI if needed
        onAddToCollection(card);
      });
    } catch (e) {
      // Show error notification
      BottomNotification.show(
        context: context,
        title: 'Error',
        message: 'Failed to add card: $e',
        icon: Icons.error_outline,
        isError: true,
      );
    }
  }
}
