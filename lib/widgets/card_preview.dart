import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import '../utils/cached_network_image.dart';

class CardPreview extends StatelessWidget {
  final TcgCard card;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CardPreview({
    super.key,
    required this.card,
    this.onTap,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'card_${card.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CardImageProvider(
            imageUrl: card.largeImageUrl,  // Changed from imageUrl
            width: width,
            height: height,
            fit: fit,
          ),
        ),
      ),
    );
  }
}
