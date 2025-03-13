import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NetworkCardImage extends StatelessWidget {
  final String? imageUrl;
  final bool highQuality; // Add this parameter
  final BoxFit fit; // Add this parameter
  final double? height; // Add this parameter
  final double? width; // Add this parameter
  
  const NetworkCardImage({
    Key? key,
    this.imageUrl,
    this.highQuality = true, // Default to high quality
    this.fit = BoxFit.cover, // Default to cover
    this.height,
    this.width,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: Colors.grey[800],
        height: height,
        width: width,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.white60),
        ),
      );
    }
    
    // If we're in low quality mode, use a simpler approach for better performance
    if (!highQuality) {
      return Image.network(
        imageUrl!,
        fit: fit,
        height: height,
        width: width,
        cacheHeight: 150, // Lower resolution for faster loading
        cacheWidth: 100,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[800],
          height: height,
          width: width,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white60),
          ),
        ),
      );
    }
    
    // Use CachedNetworkImage for higher quality rendering with caching
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: fit,
      height: height,
      width: width,
      placeholder: (context, url) => Container(
        color: Colors.grey[800],
        height: height,
        width: width,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[800],
        height: height,
        width: width,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white60),
        ),
      ),
    );
  }
}
