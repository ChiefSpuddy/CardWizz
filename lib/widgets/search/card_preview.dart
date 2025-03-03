import 'package:flutter/material.dart';
import '../../models/tcg_card.dart';

// Add this helper method at the top of the file or in a utility class
String _uniqueHeroTag(String baseTag, int index, String context) {
  return '${baseTag}_${context}_${index}_${DateTime.now().millisecondsSinceEpoch}';
}

class CardPreview extends StatelessWidget {
  final TcgCard card;
  final Image? cachedImage;
  final int index;
  final bool isLoading;
  // other properties...

  const CardPreview({
    Key? key,
    required this.card,
    this.cachedImage,
    required this.index,
    this.isLoading = false,
    // other params...
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The problem might be here, where a fixed tag is used
    // Let's modify the Hero to use a unique tag that includes both card ID and index
    final uniqueTag = 'card_preview_${card.id}_$index';
    
    return Container(
      // ...existing container properties
      child: cachedImage != null ? 
        Hero(
          // Replace this tag with our unique version
          tag: _uniqueHeroTag('card_preview', index, 'default'),
          child: Image(image: cachedImage!.image, fit: BoxFit.contain),
        ) : 
        _buildEmptyPreview(),
    );
  }

  Widget _buildEmptyPreview() {
    // This is likely where the problem is - the empty preview might be using a fixed tag
    // Let's use a unique tag for empty previews too
    final uniqueEmptyTag = 'empty_preview_${card.id}_$index';

    return Hero(
      // Replace the likely fixed tag with our unique version
      tag: _uniqueHeroTag('empty_preview', index, 'default'),
      child: Container(
        color: Colors.grey.withOpacity(0.2),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
