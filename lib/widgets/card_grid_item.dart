import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../providers/currency_provider.dart';
import '../utils/card_details_router.dart'; // Add this import for getRawCardPrice method
import '../services/storage_service.dart'; // Add this import
import '../utils/notification_manager.dart'; // Add this import for NotificationManager
import '../utils/hero_tags.dart';

class CardGridItem extends StatelessWidget {
  final TcgCard card;
  final Function(TcgCard) onCardTap;
  final bool isInCollection;
  final bool preventNavigationOnQuickAdd;
  final bool showPrice;
  final bool showName;
  final String heroContext;
  final String? currencySymbol;

  const CardGridItem({
    Key? key,
    required this.card,
    required this.onCardTap,
    this.isInCollection = false,
    this.preventNavigationOnQuickAdd = false,
    this.showPrice = true,
    this.showName = false,
    required this.heroContext,
    this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final cardBorderRadius = BorderRadius.circular(6);
    
    // Get the currency provider for proper formatting
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final storageService = Provider.of<StorageService>(context, listen: false);

    return GestureDetector(
      onTap: () => onCardTap(card),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: cardBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: cardBorderRadius,
          child: Container(
            color: isDarkMode 
                ? theme.colorScheme.surfaceVariant.withOpacity(0.8)
                : theme.colorScheme.surface,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card image - expanded to fill available space
                    Expanded(
                      child: Hero(
                        tag: '${heroContext}_${card.id}',
                        child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                          ? Image.network(
                              card.imageUrl!,
                              fit: BoxFit.contain, // Keep contain to prevent distortion
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: isDarkMode ? Colors.black12 : Colors.grey[100],
                                  child: Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                              loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => 
                                Container(
                                  color: isDarkMode ? Colors.black12 : Colors.grey[100],
                                  child: const Center(child: Icon(Icons.broken_image)),
                                ),
                            )
                          : Container(
                              color: isDarkMode ? Colors.black12 : Colors.grey[100],
                              child: const Center(child: Icon(Icons.image_not_supported)),
                            ),
                      ),
                    ),

                    // Info section - more compact with number and price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      color: isDarkMode ? Colors.black45 : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Card name - always shown but very compact
                          if (card.name != null)
                            Text(
                              card.name!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          
                          // Price row with card number
                          if (showPrice)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Card number with hashtag
                                if (card.number != null && card.number!.isNotEmpty)
                                  Text(
                                    "#${card.number!}",
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                
                                // Price with consistent raw price fetching
                                FutureBuilder<double?>(
                                  future: CardDetailsRouter.getRawCardPrice(card),
                                  builder: (context, snapshot) {
                                    final priceValue = snapshot.data ?? card.price;
                                    
                                    // Show dash if no price available
                                    if (priceValue == null || priceValue <= 0) {
                                      return Text(
                                        '-',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                                        ),
                                      );
                                    }
                                    
                                    return Text(
                                      currencyProvider.formatValue(priceValue),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Use StreamBuilder to check if the card is in the collection
                StreamBuilder<List<dynamic>>(
                  stream: Provider.of<StorageService>(context).watchCards(),
                  builder: (context, snapshot) {
                    final cards = snapshot.data ?? [];
                    final isInCollection = cards.any((c) => c is TcgCard && c.id == card.id);
                    
                    // Move higher up to the true top-right corner
                    return Positioned(
                      top: 2,  // Reduced from 6
                      right: 2, // Reduced from 6
                      child: _buildQuickAddButton(context, isInCollection),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Updated method to build the quick add button
  Widget _buildQuickAddButton(BuildContext context, bool isInCollection) {
    // Different styles based on whether the card is already in collection
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isInCollection 
        ? Colors.green.withOpacity(0.85)
        : colorScheme.primary.withOpacity(0.85);
    final iconColor = isInCollection
        ? Colors.white
        : colorScheme.onPrimary;
    final icon = isInCollection
        ? Icons.check
        : Icons.add;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _quickAddToCollection(context, isInCollection),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              size: 15,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }

  // Updated method to handle quick add with collection status
  Future<void> _quickAddToCollection(BuildContext context, bool isInCollection) async {
    if (isInCollection) {
      // If already in collection, show confirmation message
      NotificationManager.success(
        context,
        message: 'Already in collection',
        icon: Icons.check_circle,
        position: NotificationPosition.bottom,
        compact: true,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      // Save the card to collection
      await storage.saveCard(card);
      
      // Show success notification
      NotificationManager.success(
        context,
        message: 'Added to collection',
        icon: Icons.check_circle,
        position: NotificationPosition.bottom,
        compact: true,
      );
    } catch (e) {
      // Show error notification
      NotificationManager.error(
        context,
        message: 'Failed to add card',
        icon: Icons.error_outline,
        position: NotificationPosition.bottom,
      );
    }
    
    // Prevent the tap event from propagating
    // This prevents navigation to card details when adding to collection
    return;
  }
}
