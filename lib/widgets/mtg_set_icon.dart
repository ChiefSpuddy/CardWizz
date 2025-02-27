import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MtgSetIcon extends StatefulWidget {
  final String setCode;
  final double size;
  final Color? color;

  const MtgSetIcon({
    Key? key,
    required this.setCode,
    this.size = 30,
    this.color,
  }) : super(key: key);

  @override
  State<MtgSetIcon> createState() => _MtgSetIconState();
}

class _MtgSetIconState extends State<MtgSetIcon> {
  bool _svgFailed = false;

  @override
  Widget build(BuildContext context) {
    // If SVG already failed, skip directly to fallbacks
    if (_svgFailed) {
      return _buildFallbackIcon();
    }

    final svgUrl = 'https://svgs.scryfall.io/sets/${widget.setCode.toLowerCase()}.svg';
    
    return SvgPicture.network(
      svgUrl,
      width: widget.size,
      height: widget.size,
      colorFilter: widget.color != null 
          ? ColorFilter.mode(widget.color!, BlendMode.srcIn) 
          : null,
      placeholderBuilder: (context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      semanticsLabel: 'MTG ${widget.setCode} set symbol',
      // Change 'loadErrorBuilder' to 'errorBuilder' to match the API
      errorBuilder: (context, error, stackTrace) {
        // Mark SVG as failed so we don't try again
        if (mounted) {
          setState(() => _svgFailed = true);
        }
        return _buildFallbackIcon();
      },
    );
  }

  Widget _buildFallbackIcon() {
    // Try the PNG version from Scryfall as first fallback
    final pngUrl = 'https://c2.scryfall.com/file/scryfall-symbols/sets/${widget.setCode.toLowerCase()}.png';
    
    return CachedNetworkImage(
      imageUrl: pngUrl,
      width: widget.size,
      height: widget.size,
      color: widget.color,
      // If PNG also fails, use text abbreviation as last resort
      errorWidget: (context, url, error) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(widget.size / 4),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              widget.setCode.toUpperCase(),
              style: TextStyle(
                fontSize: widget.size * 0.4,
                fontWeight: FontWeight.bold,
                color: widget.color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
      placeholder: (context, url) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
