import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/logging_service.dart';

class ZoomableCardImage extends StatefulWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final BoxFit fit;

  const ZoomableCardImage({
    Key? key,
    required this.imageUrl,
    this.height,
    this.width,
    this.onTap,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  State<ZoomableCardImage> createState() => _ZoomableCardImageState();
}

class _ZoomableCardImageState extends State<ZoomableCardImage> with SingleTickerProviderStateMixin {
  late TransformationController _controller;
  TapDownDetails? _tapDetails;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  final double _minScale = 1.0;
  final double _maxScale = 3.0;
  
  bool _isZoomed = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      if (_animation != null) {
        _controller.value = _animation!.value;
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Reset zoom when tapping outside of image
  void _handleTapReset() {
    if (_isZoomed) {
      _resetTransformation();
    } else if (widget.onTap != null) {
      widget.onTap!();
    }
  }
  
  // Handle double tap to zoom in or reset
  void _handleDoubleTap() {
    if (_isZoomed) {
      _resetTransformation();
    } else {
      _zoomIn();
    }
  }
  
  // Store position for zooming into specific point
  void _handleTapDown(TapDownDetails details) {
    _tapDetails = details;
  }
  
  void _resetTransformation() {
    _animateMatrix(Matrix4.identity());
    setState(() {
      _isZoomed = false;
    });
  }
  
  void _zoomIn() {
    if (_tapDetails == null) return;
    
    final position = _tapDetails!.localPosition;
    
    // Calculate zoom matrix
    final Matrix4 matrix = Matrix4.identity()
      ..translate(-position.dx * (_maxScale - 1), -position.dy * (_maxScale - 1))
      ..scale(_maxScale);
    
    _animateMatrix(matrix);
    setState(() {
      _isZoomed = true;
    });
  }
  
  void _animateMatrix(Matrix4 end) {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward(from: 0);
  }
  
  void _onInteractionStart(ScaleStartDetails details) {
    // Cancel any animations when user starts interacting
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
  }
  
  void _onInteractionEnd(ScaleEndDetails details) {
    // If zoom level is too low, reset
    final double scale = _controller.value.getMaxScaleOnAxis();
    if (scale < _minScale * 0.8) {
      _resetTransformation();
    }
    // If zoom level is too high, limit it
    else if (scale > _maxScale * 1.2) {
      final corrected = Matrix4.copy(_controller.value)..scale(_maxScale / scale);
      _animateMatrix(corrected);
    }
    
    setState(() {
      _isZoomed = scale > 1.1; // Consider zoomed if scale is greater than 1.1
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTapReset,
      onDoubleTap: _handleDoubleTap,
      onTapDown: _handleTapDown,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: _minScale,
        maxScale: _maxScale,
        onInteractionStart: _onInteractionStart,
        onInteractionEnd: _onInteractionEnd,
        clipBehavior: Clip.none,
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl ?? '',
          height: widget.height ?? 300,
          width: widget.width,
          fit: widget.fit,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            LoggingService.debug('Error loading image: $error');
            return Container(
              color: Colors.grey[850],
              child: const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white60,
                  size: 48,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
