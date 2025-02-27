import 'package:flutter/material.dart';
import '../../models/tcg_card.dart';

class CardGridItem extends StatelessWidget {
  final TcgCard card;
  final VoidCallback? onTap;
  final Image? cached;
  final String? heroContext;
  final bool showPrice;
  final bool showName;
  final bool isLoaded;

  const CardGridItem({
    Key? key,
    required this.card,
    this.onTap,
    this.cached,
    this.heroContext,
    this.showPrice = true,
    this.showName = false,
    this.isLoaded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Card image
          AspectRatio(
            aspectRatio: 0.7,
            child: Hero(
              tag: 'card_${card.id}_${heroContext ?? "search"}',
              child: isLoaded && cached != null
                ? cached!
                : Image.network(
                    card.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading card image: ${card.imageUrl}');
                      return Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
          
          // Tap overlay
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              highlightColor: Colors.transparent,
            ),
          ),
          
          // Optional price tag at bottom
          if (showPrice && card.price != null && card.price! > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black.withOpacity(0.6),
                child: Text(
                  '\$${card.price!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
          // Optional name at bottom
          if (showName && card.name.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: Colors.black.withOpacity(0.6),
                child: Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
