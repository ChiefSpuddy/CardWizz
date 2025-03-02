import 'package:flutter/material.dart';

class ImageHandler {
  /// Reliable fallback images that are guaranteed to work
  static const List<String> fallbackUrls = [
    'https://assets.pokemon.com/assets/cms2/img/cards/web/SWSH4/SWSH4_EN_56.png',
    'https://assets.pokemon.com/assets/cms2/img/cards/web/SWSH9/SWSH9_EN_143.png',
    'https://assets.pokemon.com/assets/cms2/img/cards/web/SM9/SM9_EN_22.png',
  ];

  /// Create a widget that reliably displays an image with proper error handling
  static Widget networkImage({
    required String url, 
    double? width, 
    double? height, 
    BoxFit fit = BoxFit.contain,
    String? heroTag,
  }) {
    final Widget imageWidget = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Try the first fallback
        return Image.network(
          fallbackUrls[0],
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // If even the fallback fails, show an icon
            return Container(
              width: width,
              height: height,
              color: Colors.grey[800],
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white70, 
                  size: 24,
                ),
              ),
            );
          },
        );
      },
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  /// Determine if a URL is likely to work or not based on patterns
  static bool isLikelyWorkingUrl(String url) {
    // These domains are more reliable
    final reliableDomains = [
      'assets.pokemon.com',
      'images.pokemontcg.io',
    ];
    
    for (final domain in reliableDomains) {
      if (url.contains(domain)) {
        return true;
      }
    }
    
    // Some patterns tend to fail
    final unreliablePatterns = [
      'pokemon-card.com',
      'bulbagarden.net',
      'archives.bulbagarden.net',
    ];
    
    for (final pattern in unreliablePatterns) {
      if (url.contains(pattern)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Get a safe URL (either the original if likely to work, or a fallback)
  static String getSafeUrl(String originalUrl) {
    if (isLikelyWorkingUrl(originalUrl)) {
      return originalUrl;
    }
    
    // Use the first fallback URL
    return fallbackUrls[0];
  }
}
