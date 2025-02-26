import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import '../constants/card_styles.dart';

class CardGridItem extends StatelessWidget {
  final TcgCard card;
  final VoidCallback? onTap;
  final Image? cached;
  final String? heroContext;
  final bool showPrice;
  final bool showName;  // Add this parameter

  const CardGridItem({
    Key? key,
    required this.card,
    this.onTap,
    this.cached,
    this.heroContext,
    this.showPrice = true,
    this.showName = false,  // Add default value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.7,
      child: Container(
        // Increased padding to give more space around the card
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            // Eliminate the border radius completely to ensure no content is cut off
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Card image with custom ClipRect to ensure no clipping at edges
              ClipRect(
                child: Hero(
                  tag: 'card_${card.id}_${heroContext ?? "search"}',
                  child: cached ?? Image.network(
                    card.imageUrl,
                    fit: BoxFit.contain, // Use contain instead of cover to avoid cropping
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              // Optional name and price tag at bottom
              if (showName || showPrice)
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.0),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showName && card.name.isNotEmpty)
                          Text(
                            card.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (showPrice && card.price != null && card.price! > 0)
                          Text(
                            '\$${card.price!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 2,
                                ),
                              ],
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
    );
  }
}
