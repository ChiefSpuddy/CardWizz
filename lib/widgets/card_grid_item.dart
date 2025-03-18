import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../providers/currency_provider.dart';

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
            child: Column(
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
                      
                      // Price row
                      if (showPrice && card.price != null)
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
                            
                            // Price with proper currency formatting
                            Text(
                              currencyProvider.formatValue(card.price!),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
