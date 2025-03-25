import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A heavily optimized version of CardGridItem that uses aggressive caching
class CachedCardGridItem extends StatelessWidget {
  final TcgCard card;
  final Function(TcgCard card)? onCardTap;
  final Function(TcgCard card)? onQuickAdd;
  final bool isInCollection;
  final String heroContext;
  final bool showPrice;
  final bool showName;
  final String? currencySymbol;
  
  // Use static options for various image sizing and scaling
  static const double _imageHeight = 120;
  static const int _memCacheWidth = 150;
  
  // Cache immutable image widgets to prevent rebuilding
  static final Map<String, Image> _cachedPlaceholders = {};
  static final Map<String, Widget> _cachedCardImages = {};

  const CachedCardGridItem({
    Key? key,
    required this.card,
    this.onCardTap,
    this.onQuickAdd,
    this.isInCollection = false,
    required this.heroContext,
    this.showPrice = false,
    this.showName = false,
    this.currencySymbol,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Generate a unique key for this card
    final cardKey = '${card.id}_$heroContext';
    
    return Hero(
      tag: heroContext,
      child: InkWell(
        onTap: () {
          if (onCardTap != null) {
            onCardTap!(card);
          }
        },
        borderRadius: BorderRadius.circular(8.0),
        child: Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildOptimizedImage(context, cardKey),
              ),
              if (showName || showPrice) ...[
                _buildCardDetails(context),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOptimizedImage(BuildContext context, String cardKey) {
    // Try to use pre-cached image widget if available
    if (_cachedCardImages.containsKey(cardKey)) {
      return _cachedCardImages[cardKey]!;
    }
    
    final imageUrl = card.imageUrl ?? '';
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }
    
    // Create a new optimized image widget and cache it
    final imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      memCacheWidth: _memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
    
    // Cache the widget for future reuse
    _cachedCardImages[cardKey] = imageWidget;
    
    return imageWidget;
  }
  
  Widget _buildPlaceholder() {
    final key = 'placeholder';
    return _cachedPlaceholders[key] ?? Container(
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
  
  Widget _buildCardDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showName) ...[
            Text(
              card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (showPrice && card.price != null) ...[
            Text(
              '${currencySymbol ?? '\$'}${card.price?.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
