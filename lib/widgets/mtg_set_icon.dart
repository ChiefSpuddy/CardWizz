import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final String svgUrl = 'https://svgs.scryfall.io/sets/$setCode.svg';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 5),
        child: Container(
          decoration: BoxDecoration(
            // Use a neutral background with subtle gradient
            gradient: LinearGradient(
              colors: isDark 
                ? [
                    colorScheme.surfaceVariant.withOpacity(0.7),
                    colorScheme.surfaceVariant.withOpacity(0.3),
                  ]
                : [
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // Add subtle border
            border: Border.all(
              color: isDark
                ? colorScheme.outlineVariant.withOpacity(0.3)
                : colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(size / 5),
          ),
          child: Center(
            child: SvgPicture.network(
              svgUrl,
              height: size * 0.6,
              width: size * 0.6,
              // Use a color for the SVG that matches the theme
              colorFilter: ColorFilter.mode(
                colorScheme.primary,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (BuildContext context) => Text(
                setCode.isEmpty ? '?' : setCode.toUpperCase().substring(0, math.min(3, setCode.length)),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
