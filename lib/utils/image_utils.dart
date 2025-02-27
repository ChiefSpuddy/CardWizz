import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tcg_card.dart';

class CardImageUtils {
  /// Get the appropriate placeholder for a card based on type
  static Widget getPlaceholder(bool isMtgCard, {double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          isMtgCard ? Icons.style : Icons.catching_pokemon,
          color: Colors.grey.shade400,
          size: (width != null) ? width * 0.4 : 24,
        ),
      ),
    );
  }

  /// Get the error widget for a card image
  static Widget getErrorWidget(bool isMtgCard, {double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey.shade400,
          size: (width != null) ? width * 0.4 : 24,
        ),
      ),
    );
  }

  /// Get the MTG set logo URL
  static String getMtgSetLogo(String setCode) {
    // Make lowercase for consistency
    final code = setCode.toLowerCase();
    return 'https://svgs.scryfall.io/sets/$code.svg';
  }
  
  /// Get the MTG set logo as PNG (fallback)
  static String getMtgSetPngLogo(String setCode) {
    // Make lowercase for consistency
    final code = setCode.toLowerCase();
    return 'https://svgs.scryfall.io/sets/$code.png';
  }

  /// Get the MTG set logo/icon URL from Scryfall
  static String getMtgSetIconUrl(String setCode) {
    final code = setCode.toLowerCase();
    return 'https://svgs.scryfall.io/sets/$code.svg';
  }

  /// Get the MTG set symbol from Gatherer as fallback
  static String getMtgSetSymbolUrl(String setCode) {
    return 'https://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=$setCode&size=large';
  }

  /// Get the Pokemon set logo URL
  static String getPokemonSetLogo(String setCode) {
    // Make lowercase for consistency
    final code = setCode.toLowerCase();
    return 'https://images.pokemontcg.io/$code/logo.png';
  }
  
  /// Get the Japanese Pokemon set logo URL
  static String getJapaneseSetLogo(String setCode) {
    return 'https://raw.githubusercontent.com/tcgdex/cards-database/main/src/assets/sets/$setCode.png';
  }

  /// Load a set logo with fallbacks
  static Widget loadSetLogo(String setCode, {bool isMtg = false, double? size, Color? color}) {
    if (isMtg) {
      final svgUrl = getMtgSetLogo(setCode);
      final pngUrl = getMtgSetPngLogo(setCode);
      
      return CachedNetworkImage(
        imageUrl: svgUrl,
        width: size,
        height: size,
        color: color,
        errorWidget: (context, url, error) {
          return CachedNetworkImage(
            imageUrl: pngUrl,
            width: size,
            height: size,
            errorWidget: (context, url, error) {
              return Icon(Icons.help_outline, size: size ?? 24, color: Colors.grey);
            },
          );
        },
      );
    } else {
      final url = getPokemonSetLogo(setCode);
      
      return CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        errorWidget: (context, url, error) {
          return Icon(Icons.help_outline, size: size ?? 24, color: Colors.grey);
        },
      );
    }
  }

  /// Create a cached image widget for a card
  static Widget createCachedImage(
    String url, {
    bool isMtgCard = false,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool useHero = false,
    String? heroTag,
  }) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => getPlaceholder(isMtgCard, width: width, height: height),
      errorWidget: (context, url, error) => getErrorWidget(isMtgCard, width: width, height: height),
    );

    if (useHero && heroTag != null) {
      return Hero(
        tag: heroTag,
        child: image,
      );
    }

    return image;
  }

  /// Load an image for display in the UI with better error handling
  static Widget loadImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BuildContext? context, // Add optional context parameter
    Widget? placeholder, // Add optional placeholder parameter
  }) {
    // Add debug logging
    print('Loading image from URL: $url');
    
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('Error loading image: $url - $error');
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.grey.shade400,
            ),
          ),
        );
      },
    );
  }
}
