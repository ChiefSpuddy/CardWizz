import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tcg_card.dart';
import '../services/logging_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Service for optimizing image loading and caching throughout the app
class ImageOptimizingService {
  static final ImageOptimizingService _instance = ImageOptimizingService._internal();
  
  factory ImageOptimizingService() => _instance;
  
  ImageOptimizingService._internal() {
    // Initialize the cache manager with optimal settings
    _cacheManager = CustomCacheManager();
  }
  
  // Custom cache manager with optimized settings
  late final BaseCacheManager _cacheManager;
  
  // Keep track of preloaded images to avoid redundant work
  final Set<String> _preloadedImages = <String>{};
  
  /// Preload images for a list of cards
  Future<void> preloadCardImages(List<TcgCard> cards) async {
    if (cards.isEmpty) return;
    
    // Calculate how many images to preload based on available memory
    final deviceMemory = 128; // Assume 128MB as conservative default
    
    // Assuming each image is around 500KB, limit to 20% of available memory
    final maxImages = (deviceMemory * 0.2 * 1000 ~/ 500).clamp(10, 100);
    
    // Prioritize unloaded images first
    final imagesToLoad = cards
        .where((card) => card.imageUrl != null && card.imageUrl!.isNotEmpty)
        .map((card) => card.imageUrl!)
        .where((url) => !_preloadedImages.contains(url))
        .take(maxImages)
        .toList();
    
    if (imagesToLoad.isEmpty) return;
    
    LoggingService.debug('Preloading ${imagesToLoad.length} images');
    
    // Process in batches for smoother UI
    const batchSize = 5;
    for (int i = 0; i < imagesToLoad.length; i += batchSize) {
      final end = (i + batchSize < imagesToLoad.length) ? i + batchSize : imagesToLoad.length;
      final batch = imagesToLoad.sublist(i, end);
      
      // Load batch in parallel
      await Future.wait(
        batch.map((url) => _preloadSingleImage(url)),
      );
      
      // Give UI thread a break
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
  
  Future<void> _preloadSingleImage(String url) async {
    try {
      // Mark as preloaded to avoid redundant work
      _preloadedImages.add(url);
      
      // Use custom cache manager
      await _cacheManager.getSingleFile(url);
      
    } catch (e) {
      LoggingService.debug('Error preloading image: $e');
    }
  }
  
  /// Clear image cache when running low on memory
  void clearCache() {
    _cacheManager.emptyCache();
    _preloadedImages.clear();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    LoggingService.debug('Image caches cleared');
  }
  
  /// Get cached network image with optimal settings
  Widget getOptimizedImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
    bool fadeIn = true,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ?? const SizedBox.shrink();
    }
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeIn ? const Duration(milliseconds: 200) : Duration.zero,
      cacheManager: _cacheManager,
      memCacheWidth: width != null ? (width * 1.5).toInt() : null,
      placeholder: (context, url) => placeholder ?? const SizedBox.shrink(),
      errorWidget: (context, url, error) => errorWidget ?? const SizedBox.shrink(),
    );
  }
}

/// Custom cache manager with optimized settings
class CustomCacheManager extends CacheManager {
  static const key = 'cardwizz_image_cache';
  
  static final CustomCacheManager _instance = CustomCacheManager._();
  
  factory CustomCacheManager() => _instance;
  
  CustomCacheManager._() : super(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 300,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
