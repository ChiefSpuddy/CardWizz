import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../services/connectivity_service.dart';
import '../services/image_cache_service.dart';

class CardImageProvider extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CardImageProvider({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  State<CardImageProvider> createState() => _CardImageProviderState();
}

class _CardImageProviderState extends State<CardImageProvider> {
  final ConnectivityService _connectivity = ConnectivityService();
  final ImageCacheService _imageCache = ImageCacheService();
  bool _isOffline = false;
  bool _isLoading = true;
  int _retryCount = 0;
  static const maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenToConnectivity();
    _precacheImage();
  }

  Future<void> _precacheImage() async {
    if (!_isOffline) {
      await _imageCache.cacheImage(widget.imageUrl);
    }
  }

  Future<void> _checkConnectivity() async {
    final isOffline = !await _connectivity.isConnected();
    if (mounted && isOffline != _isOffline) {
      setState(() => _isOffline = isOffline);
    }
  }

  void _listenToConnectivity() {
    _connectivity.onConnectivityChanged.listen((isConnected) {
      if (mounted && _isOffline == isConnected) {
        setState(() => _isOffline = !isConnected);
        if (isConnected && _isLoading) {
          _retryLoad();
        }
      }
    });
  }

  Future<void> _retryLoad() async {
    if (_retryCount >= maxRetries) return;
    
    _retryCount++;
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    // Force cache check
    await _imageCache.getCachedImagePath(widget.imageUrl);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageCache.getCachedImagePath(widget.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Use cached image if available
          return Image.file(
            File(snapshot.data!),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        }

        // Otherwise use CachedNetworkImage with error handling
        return CachedNetworkImage(
          imageUrl: widget.imageUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorWidget(),
        );
      },
    );
  }

  Widget _buildPlaceholder({bool hasBackup = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/card_placeholder.png',
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
          ),
          if (!hasBackup)
            const CircularProgressIndicator(strokeWidth: 2),
        ],
      ),
    );
  }

  Widget _buildErrorWidget({String? backupPath}) {
    if (backupPath != null) {
      return Image.file(
        File(backupPath),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/card_placeholder.png',
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
          ),
          if (_isOffline)
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 14,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
