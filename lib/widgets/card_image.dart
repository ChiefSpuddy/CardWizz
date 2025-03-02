import 'package:flutter/material.dart';
import '../utils/image_handler.dart';
// ... other imports

class CardImage extends StatelessWidget {
  final String imageUrl;
  final String? largeImageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isSelectable;
  final bool isJapanese;
  final bool isMtg;
  final String? heroTag;
  
  const CardImage({
    super.key,
    required this.imageUrl,
    this.largeImageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.isSelectable = false,
    this.isJapanese = false,
    this.isMtg = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // Use the ImageHandler to always get a working image
    return ImageHandler.networkImage(
      url: imageUrl,
      width: width,
      height: height,
      fit: fit,
      heroTag: heroTag,
    );
  }
}
