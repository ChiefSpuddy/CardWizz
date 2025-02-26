import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/logo_cache_manager.dart';

class SetLogoWidget extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final String? setCode;
  final Color? color;

  const SetLogoWidget({
    Key? key,
    this.logoUrl,
    this.setCode,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the logo URL either directly or from the set code
    String? effectiveLogoUrl = logoUrl;
    if (effectiveLogoUrl == null && setCode != null) {
      effectiveLogoUrl = LogoCacheManager.getLogoUrl(setCode!);
    }

    // If we don't have a URL, show a fallback
    if (effectiveLogoUrl == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(
          Icons.extension,
          size: size * 0.8,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      );
    }

    // If it's an SVG file, use SVG renderer
    if (effectiveLogoUrl.toLowerCase().endsWith('.svg')) {
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.network(
          effectiveLogoUrl,
          placeholderBuilder: (context) => const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
          colorFilter: color != null 
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
        ),
      );
    }

    // Otherwise use regular image caching
    return CachedNetworkImage(
      imageUrl: effectiveLogoUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Icon(
        Icons.broken_image,
        size: size * 0.8,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// Extension method to capitalize string
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
  }
}
