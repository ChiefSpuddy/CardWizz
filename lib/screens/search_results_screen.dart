import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../widgets/card_grid_item.dart';
import '../services/logging_service.dart';
import '../utils/notification_manager.dart';

class SearchResultsScreen extends StatefulWidget {
  final List<TcgCard> cards;
  final String searchTerm;

  const SearchResultsScreen({
    super.key,
    required this.cards,
    required this.searchTerm,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  // Track cards that have been added to collection locally
  final Set<String> _addedCardIds = <String>{};
  bool _processingCard = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Results for '${widget.searchTerm}'"),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.68,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          final isInCollection = _addedCardIds.contains(card.id);
          
          return CardGridItem(
            card: card,
            heroContext: 'search_results_$index',
            onTap: () => _navigateToCardDetails(card, index),
            onAddToCollection: () => _quickAddToCollection(card),
            isInCollection: isInCollection,
            showPrice: true,
            showName: true,
            highQuality: true,
          );
        },
      ),
    );
  }
  
  void _navigateToCardDetails(TcgCard card, int index) {
    // Use rootNavigator to ensure we're at the top level
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/card',
      arguments: {
        'card': card,
        'heroContext': 'search_results_$index',
      },
    );
  }

  void _quickAddToCollection(TcgCard card) {
    // Skip if already added
    if (_addedCardIds.contains(card.id)) return;
    
    // Update UI immediately for responsive feedback
    setState(() {
      _addedCardIds.add(card.id);
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Get storage service
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    // CRITICAL FIX: Use preventNavigation flag to avoid navigation issues
    storageService.saveCard(card, preventNavigation: true).then((_) {
      // Use our unified notification system with isSuccess explicitly set to true
      NotificationManager.success(
        context,
        message: 'Added ${card.name} to collection',
        icon: Icons.add_circle_outline,
        preventNavigation: true, // Critical for search results screen
        position: NotificationPosition.bottom,
      );
    }).catchError((e) {
      // Revert UI state
      setState(() {
        _addedCardIds.remove(card.id);
      });
      
      // Show error notification
      NotificationManager.error(
        context,
        message: 'Error: $e',
      );
    });
  }
}
