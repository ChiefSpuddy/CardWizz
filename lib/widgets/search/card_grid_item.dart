import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; 
import '../../services/storage_service.dart';
import '../../models/tcg_card.dart';
import '../../constants/app_colors.dart';
import '../../providers/app_state.dart';

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
          child: GestureDetector(
            // CRITICAL FIX: Using GestureDetector with behavior opaque stops ALL event propagation
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Stop event propagation completely and call add function directly
              onAddToCollection(card);
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
      ],
    );
  }
}
