import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; 
import '../../services/storage_service.dart';
import '../../models/tcg_card.dart';
import '../../constants/app_colors.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_notification.dart';

class CardGridItem extends StatelessWidget {
  final TcgCard card;
  final Image? cachedImage;
  final Function(TcgCard) onCardTap;
  final Function(TcgCard) onAddToCollection;
  final bool isInCollection;
  final String? currencySymbol;

  const CardGridItem({
    Key? key,
    required this.card,
    this.cachedImage,
    required this.onCardTap,
    required this.onAddToCollection,
    this.isInCollection = false,
    this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedPrice = card.price != null && card.price! > 0
        ? '${currencySymbol ?? '\$'}${card.price!.toStringAsFixed(2)}'
        : '';

    return Stack(
      children: [
        // The main card itself
        GestureDetector(
          onTap: () => onCardTap(card),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              boxShadow: AppColors.getCardShadow(elevation: 2.0, isDark: isDark),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Card image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: isDark ? Colors.grey[850] : Colors.grey[300],
                    child: cachedImage ?? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom info overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 6, right: 6, bottom: 6, top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        if (card.price != null && card.price! > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              formattedPrice,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Add button - completely separate tap handler with zero interaction with parent
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // CRITICAL: Use Material+InkWell instead of GestureDetector to prevent event bubbling
              borderRadius: BorderRadius.circular(13),
              onTap: () {
                // Add haptic feedback for better user experience
                HapticFeedback.lightImpact();
                
                // CRITICAL: Handle card addition directly here without callback
                try {
                  // Get the storage service directly
                  final storageService = Provider.of<StorageService>(context, listen: false);
                  
                  // FIXED: First update the UI state immediately to show the check
                  // This makes the UI feel responsive without needing to rebuild the entire grid
                  if (context.mounted && !isInCollection) {
                    // We don't wait for the async operation to complete here
                    showBottomNotification(context);
                  }
                  
                  // Save card in background using microtask to avoid blocking UI thread
                  Future.microtask(() async {
                    try {
                      // Do the actual saving in a background task
                      await storageService.saveCard(card);
                      
                      // Only notify AppState after successful save
                      if (context.mounted) {
                        // Notify the app state in a delayed manner to avoid navigation issues
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (context.mounted) {
                            final appState = Provider.of<AppState>(context, listen: false);
                            appState.notifyCardChange();
                          }
                        });
                      }
                    } catch (e) {
                      // If error occurs, show error notification
                      if (context.mounted) {
                        BottomNotification.show(
                          context: context,
                          title: 'Error',
                          message: 'Failed to add card: $e',
                          icon: Icons.error_outline,
                          isError: true,
                        );
                      }
                    }
                  });
                } catch (e) {
                  debugPrint('Error in direct add: $e');
                }
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isInCollection
                      ? Colors.green.withOpacity(0.8)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isInCollection ? Icons.check : Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // New helper method to show notification without triggering navigation issues
  void showBottomNotification(BuildContext context) {
    BottomNotification.show(
      context: context,
      title: 'Card Added',
      message: '${card.name} added to collection',
      icon: Icons.check_circle,
    );
  }
}
