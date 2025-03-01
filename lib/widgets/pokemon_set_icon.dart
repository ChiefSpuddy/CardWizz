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
    this.color, // We'll ignore this parameter in dark mode
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we have a valid set ID
    if (setId.isEmpty) {
      return _buildFallback(context);
    }
    
    final normalizedSetId = setId.toLowerCase().trim();
    
    // Base URL for logos
    const baseUrl = 'https://images.pokemontcg.io';
    
    // Try the logo path
    final logoUrl = '$baseUrl/$normalizedSetId/logo.png';
    final symbolUrl = '$baseUrl/$normalizedSetId/symbol.png';
    
    // Check if we're in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Simple fix: Never apply color tint in dark mode
    final appliedColor = isDarkMode ? null : color;

    return CachedNetworkImage(
      imageUrl: logoUrl,
      width: size * 2, // Logos are wider
      height: size,
      fit: BoxFit.contain,
      color: appliedColor, // No color filter in dark mode
      errorWidget: (context, url, error) {
        // Try the symbol path if logo fails
        return CachedNetworkImage(
          imageUrl: symbolUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: appliedColor, // No color filter in dark mode
          errorWidget: (context, url, error) {
            return _buildFallback(context);
          },
        );
      },
    );
  }
  
  Widget _buildFallback(BuildContext context) {
    // Fallback text representation
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
          setId.isEmpty
              ? '?'
              : setId.length > 2 
                  ? setId.substring(0, 2).toUpperCase() 
                  : setId.toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
