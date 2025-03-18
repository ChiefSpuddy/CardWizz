import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../widgets/card_grid_item.dart';
import '../services/logging_service.dart';
import '../utils/notification_manager.dart';
import '../utils/card_details_router.dart'; // Add this import if missing
import '../widgets/card_grid.dart'; // Update this import
import '../providers/currency_provider.dart'; // Add this import for CurrencyProvider

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
    // Get the currency provider for proper price conversion
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Results for '${widget.searchTerm}'"),
      ),
      body: widget.cards.isEmpty
          ? _buildEmptyResultsView()
          : SingleChildScrollView(
              child: CardGrid(
                cards: widget.cards,
                onCardTap: (card) {
                  // Update this line to pass the fromSearchResults flag
                  CardDetailsRouter.navigateToCardDetails(
                    context, 
                    card, 
                    heroContext: 'search_results',
                    fromSearchResults: true // Add this parameter
                  );
                },
                preventNavigationOnQuickAdd: true,
                showPrice: true,
                showName: true,
                heroContext: 'search_results',
                scrollable: false, // Critical - non-scrollable when inside SingleChildScrollView
                crossAxisCount: 3, // Show more cards per row
                childAspectRatio: 0.72, // Adjusted for better proportions
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10), // Better padding
                currencySymbol: currencyProvider.symbol, // Pass currency symbol
              ),
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

  Widget _buildCardGrid(List<dynamic> cards) {
    return CardGrid(
      cards: cards.cast<TcgCard>(),
      onCardTap: (card) {
        CardDetailsRouter.navigateToCardDetails(context, card, heroContext: 'search_results');
      },
      preventNavigationOnQuickAdd: true,
      showPrice: true,
      showName: true,
      heroContext: 'search_results',
      scrollable: true, // Explicitly set to true here
    );
  }

  Widget _buildEmptyResultsView() {
    return Center(
      child: Text('No results found for "${widget.searchTerm}"'),
    );
  }

  Widget _buildSearchResultItem(TcgCard card, int index) {
    return CardGridItem(
      card: card,
      onCardTap: (card) {
        // Handle tap on search result
        Navigator.pushNamed(
          context,
          '/card',
          arguments: {
            'card': card,
            'heroContext': 'search_$index',
            'isFromCollection': false
          },
        );
      },
      isInCollection: false, // Assuming search results are not necessarily in collection
      heroContext: 'search_${card.id}',
      showPrice: true,
      showName: true,
      currencySymbol: Provider.of<CurrencyProvider>(context, listen: false).symbol,
    );
  }
}
