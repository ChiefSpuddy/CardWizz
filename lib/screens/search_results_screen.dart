import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../widgets/card_grid_item.dart';
import '../providers/app_state.dart';
import '../widgets/bottom_notification.dart';
import '../services/logging_service.dart';
import 'package:flutter/services.dart';
import '../utils/card_navigation_helper.dart';

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
  // Track cards that have been added to the collection
  final Set<String> _addedCardIds = <String>{};
  
  // New field to prevent multiple simultaneous card saving operations
  final Set<String> _processingCardIds = <String>{};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Results for '${widget.searchTerm}'"),
        automaticallyImplyLeading: true,
      ),
      body: GridView.builder(
        padding: EdgeInsets.zero, // Remove all padding to maximize space
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Keep 3 cards per row
          childAspectRatio: 0.68, // Better card proportions
          crossAxisSpacing: 0, // Remove horizontal spacing between cards
          mainAxisSpacing: 1, // Minimal vertical spacing
        ),
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          final isProcessing = _processingCardIds.contains(card.id);
          
          return Stack(
            children: [
              CardGridItem(
                card: card,
                heroContext: 'results_$index', // Unique hero context based on index
                // CRITICAL FIX: Create explicit function to guarantee navigation context
                onTap: () {
                  LoggingService.debug('Navigating to card details for ${card.name}');
                  CardNavigationHelper.navigateToCardDetails(
                    context, 
                    card, 
                    heroContext: 'results_$index'
                  );
                },
                onAddToCollection: () => _quickAddCard(card),
                isInCollection: _addedCardIds.contains(card.id),
              ),
              
              // Transparent overlay to prevent interaction while processing
              if (isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Remove the _onCardTap method entirely since we now handle navigation directly
  // in the card item's onTap callback
  
  // Complete redesign of the method to prevent navigation issues
  void _quickAddCard(TcgCard card) {
    // Skip if already in collection
    if (_addedCardIds.contains(card.id)) return;
    
    // Apply simple haptic feedback
    HapticFeedback.lightImpact();
    
    // Update UI immediately
    setState(() {
      _addedCardIds.add(card.id);
    });
    
    // Access service directly
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    // CRITICAL FIX: Use a synchronous approach that won't trigger navigation
    // We do this outside the current build cycle to prevent any rebuild issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a try-catch block to handle errors gracefully
      try {
        // Save the card without awaiting - this is key to preventing navigation issues
        storageService.saveCard(card).then((_) {
          // Only show the snackbar if still mounted and don't try anything fancy
          if (mounted) {
            // Use the simplest possible notification that won't affect navigation
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added ${card.name}')),
            );
          }
        });
      } catch (e) {
        // Revert UI state on error
        if (mounted) {
          setState(() {
            _addedCardIds.remove(card.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding card'))
          );
        }
      }
    });
  }
}
