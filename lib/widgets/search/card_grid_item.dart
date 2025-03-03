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
    
    return GestureDetector(
      onTap: () => onCardTap(card),
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
                        '${currencySymbol ?? '\$'}${card.price!.toStringAsFixed(2)}',
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
          
          // Add to collection button (top-right corner)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: isInCollection 
                  ? Colors.green.withOpacity(0.9)
                  : AppColors.primary.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  try {
                    await onAddToCollection(card);
                    
                    // Make sure to update any necessary global state - you'd need to implement this
                    if (context.mounted) {
                      Provider.of<AppState>(context, listen: false).notifyCardChange();
                    }
                  } catch (e) {
                    print('Error adding card to collection: $e');
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: Icon(
                    isInCollection ? Icons.check : Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
