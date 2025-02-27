import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MtgSetIcon extends StatelessWidget {
  final String setCode;
  final double size;
  final Color? color;

  const MtgSetIcon({
    Key? key,
    required this.setCode,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Direct link to Gatherer's set symbols - these are PNG images that should load reliably
    final imageUrl = 'https://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=$setCode&size=large';

    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        color: color,
        errorBuilder: (context, error, stackTrace) {
          // Fallback - don't show a circle with text, show an icon
          return Icon(
            Icons.style,
            size: size * 0.8,
            color: color ?? Theme.of(context).colorScheme.primary,
          );
        },
      ),
    );
  }
}
