import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/network_card_image.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_notification.dart';

class CardGridItem extends StatelessWidget {
  final TcgCard card;
  final VoidCallback onTap;
  final VoidCallback onAddToCollection;
  final bool isInCollection;
  final bool showPrice;
  final bool showName;
  final bool highQuality;
  final String heroContext;
  final bool hideCheckmarkWhenInCollection;

  const CardGridItem({
    super.key,
    required this.card,
    required this.onTap,
    required this.onAddToCollection,
    this.isInCollection = false,
    this.showPrice = true,
    this.showName = true,
    this.highQuality = true,
    this.heroContext = 'default',
    this.hideCheckmarkWhenInCollection = false,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'card_${card.id}_${heroContext}_grid';
    
    return Stack(
      children: [
        // Card image and details
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // CRITICAL FIX: Ensure onTap receives its own handler separate from InkWell
              // and always use a new function to prevent closure issues
              onTap: () {
                // This separate function ensures we don't have closure issues
                onTap();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card image
                  Expanded(
                    child: Hero(
                      tag: heroTag,
                      child: NetworkCardImage(
                        imageUrl: card.imageUrl,
                        highQuality: highQuality,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  // Card info footer
                  if (showName || (showPrice && card.price != null))
                    Container(
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showName)
                            Text(
                              card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (showPrice && card.price != null)
                            Consumer<CurrencyProvider>(
                              builder: (context, currencyProvider, _) => Text(
                                '${currencyProvider.symbol}${card.price!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Add button or checkmark - with improved tap handling
        if (!isInCollection || !hideCheckmarkWhenInCollection)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,  // CRITICAL: Prevents tap events from propagating
              onTap: isInCollection ? null : () {
                // IMPORTANT: Stop propagation to prevent navigation issues
                // Add card directly without calling the callback
                HapticFeedback.lightImpact();

                // Use a separate handler that won't trigger navigation
                onAddToCollection();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isInCollection
                      ? Colors.green.withOpacity(0.9)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
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
      ],
    );
  }
}
