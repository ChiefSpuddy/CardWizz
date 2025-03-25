import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tcg_card.dart';
import '../services/logging_service.dart';
import 'dart:math'; // Add this for the min function

/// Service to manage image prefetching for improved performance
class ImagePrefetchService {
  static final ImagePrefetchService _instance = ImagePrefetchService._internal();
  
  factory ImagePrefetchService() => _instance;
  
  ImagePrefetchService._internal();
  
  /// Set of already prefetched image URLs to avoid duplicates
  final Set<String> _prefetchedUrls = {};
  
  /// Queue for limiting simultaneous prefetches
  final List<String> _prefetchQueue = [];
  
  /// Flag to track if prefetch is running
  bool _isPrefetchRunning = false;
  
  /// Maximum number of simultaneous prefetches
  final int _maxSimultaneousPrefetches = 5;
  
  /// Prefetch images for a list of cards to speed up UI rendering
  Future<void> prefetchCardImages(List<TcgCard> cards) async {
    if (cards.isEmpty) return;
    
    LoggingService.debug('Starting prefetch for ${cards.length} cards');
    
    // Only queue new images that haven't been prefetched yet
    // Fixed: Use imageUrl instead of smallImageUrl
    final urls = cards
        .where((card) => card.imageUrl != null && card.imageUrl!.isNotEmpty)
        .map((card) => card.imageUrl!)
        .where((url) => !_prefetchedUrls.contains(url))
        .toList();
    
    if (urls.isEmpty) return;
    
    // Add URLs to queue
    _prefetchQueue.addAll(urls);
    
    // Start processing if not already running
    if (!_isPrefetchRunning) {
      _processPrefetchQueue();
    }
  }
  
  /// Process the prefetch queue with limited concurrency
  Future<void> _processPrefetchQueue() async {
    if (_prefetchQueue.isEmpty) {
      _isPrefetchRunning = false;
      return;
    }
    
    _isPrefetchRunning = true;
    
    // Process items in batches for better performance
    final batch = _prefetchQueue.take(_maxSimultaneousPrefetches).toList();
    _prefetchQueue.removeRange(0, min(batch.length, _prefetchQueue.length));
    
    // Prefetch all items in the batch in parallel
    await Future.wait(
      batch.map((url) => _prefetchSingleImage(url)),
    );
    
    // Continue with next batch
    _processPrefetchQueue();
  }
  
  /// Prefetch a single image and handle errors
  Future<void> _prefetchSingleImage(String url) async {
    try {
      // Mark as prefetched immediately to avoid duplicates
      _prefetchedUrls.add(url);
      
      // Start actual prefetch
      await CachedNetworkImageProvider(url).resolve(ImageConfiguration.empty);
      
      LoggingService.debug('Successfully prefetched: $url');
    } catch (e) {
      LoggingService.debug('Error prefetching image: $e');
    }
  }
  
  /// Clear prefetch cache - useful when low on memory
  void clearCache() {
    _prefetchedUrls.clear();
  }
}
