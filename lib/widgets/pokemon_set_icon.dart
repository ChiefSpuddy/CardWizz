import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PokemonSetIcon extends StatelessWidget {
  final String setId;
  final double size;
  final Color? color;

  const PokemonSetIcon({
    super.key,
    required this.setId,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we have a valid set ID
    final normalizedSetId = setId.toLowerCase().trim();
    
    // Base URL for logos
    const baseUrl = 'https://images.pokemontcg.io';
    
    // Try the preferred logo path
    final logoUrl = '$baseUrl/$normalizedSetId/logo.png';
    final symbolUrl = '$baseUrl/$normalizedSetId/symbol.png';

    return CachedNetworkImage(
      imageUrl: logoUrl,
      width: size * 2, // Logos are wider
      height: size,
      fit: BoxFit.contain,
      color: color,
      errorWidget: (context, url, error) {
        // Try the symbol path if logo fails
        return CachedNetworkImage(
          imageUrl: symbolUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: color,
          errorWidget: (context, url, error) {
            // If both fail, show text fallback
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  normalizedSetId.length > 2 ? normalizedSetId.substring(0, 2).toUpperCase() : normalizedSetId.toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
