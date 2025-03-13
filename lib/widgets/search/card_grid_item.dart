import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tcg_card.dart';

class CardGridItem extends StatelessWidget {
  final TcgCard card;
  final Function(TcgCard) onCardTap;
  final Function(TcgCard) onAddToCollection;
  final bool isInCollection;
  final String? currencySymbol;

  const CardGridItem({
    Key? key,
    required this.card,
    required this.onCardTap,
    required this.onAddToCollection,
    this.isInCollection = false,
    this.currencySymbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the best image URL from multiple possible sources
    String? imageUrl;
    
    // Try the card.imageUrl first (should work after our fixes)
    if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
      imageUrl = card.imageUrl;
    }
    
    // Handle URLs starting with //
    if (imageUrl != null && imageUrl.startsWith('//')) {
      imageUrl = 'https:$imageUrl';
    }
    
    // Check rawData as a fallback
    if ((imageUrl == null || imageUrl.isEmpty) && card.rawData != null) {
      if (card.rawData!['images'] != null) {
        imageUrl = card.rawData!['images']['small'];
      }
      
      // Fix URL format if needed
      if (imageUrl != null && imageUrl.startsWith('//')) {
        imageUrl = 'https:$imageUrl';
      }
    }
    
    // Last resort - try to construct a URL based on card ID
    if ((imageUrl == null || imageUrl.isEmpty) && card.id.isNotEmpty) {
      final setId = card.set.id.isNotEmpty ? card.set.id : card.id.split('-')[0];
      final number = card.number ?? card.id.split('-')[1];
      
      // Try to construct a URL based on standard Pokemon TCG URL pattern
      imageUrl = 'https://images.pokemontcg.io/$setId/$number.png';
    }

    return GestureDetector(
      onTap: () => onCardTap(card),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onAddToCollection(card);
      },
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Direct image display with fallback
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl != null 
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
                ),
                
                if (isInCollection)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'IN COLLECTION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (card.price != null) 
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${currencySymbol ?? '\$'}${card.price!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'No image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
