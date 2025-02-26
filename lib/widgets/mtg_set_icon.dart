import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/image_utils.dart';

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
    final svgUrl = 'https://svgs.scryfall.io/sets/$setCode.svg';
    final pngUrl = 'https://gatherer.wizards.com/Handlers/Image.ashx?type=symbol&set=$setCode&size=large';
    
    return SvgPicture.network(
      svgUrl,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      placeholderBuilder: (context) => _buildLoading(),
      errorBuilder: (context, error, _) {
        print('SVG failed, trying PNG: $error');
        return Image.network(
          pngUrl,
          width: size,
          height: size,
          errorBuilder: (context, error, _) => _buildFallback(context),
        );
      },
      semanticsLabel: 'MTG Set: $setCode',
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      width: size,
      height: size,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          setCode.toUpperCase().substring(0, min(2, setCode.length)),
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  // Helper for min function
  int min(int a, int b) => a < b ? a : b;
}
