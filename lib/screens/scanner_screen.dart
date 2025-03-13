import '../services/logging_service.dart';
import 'dart:io';  // Add this import
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Add this import for DeviceOrientation
import 'package:provider/provider.dart';
import '../services/scanner_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math'; // Add this import for pi
import '../models/tcg_card.dart';  // Add this import for TcgCard class

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver, TickerProviderStateMixin {  // Add TickerProviderStateMixin
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  late ScannerService _scannerService;
  bool _isLoading = true;
  TcgCard? _scannedCard;
  bool _isSearching = false;
  String? _capturedImagePath;

  // Add card dimensions constants
  static const double cardAspectRatio = 2.5 / 3.5;  // Standard trading card ratio
  static const double overlayOpacity = 0.8;
  double? _previewAspectRatio;

  double _scanAnimation = 0.0;  // Add this field
  AnimationController? _animationController;  // Add this field

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerService = context.read<ScannerService>();
    _checkPermissionAndInitializeCamera();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start the scanning animation immediately
    _startScanningAnimation();
  }

  void _startScanningAnimation() {
    _animationController?.repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _checkPermissionAndInitializeCamera();
    }
  }

  Future<void> _checkPermissionAndInitializeCamera() async {
    try {
      // First try to initialize the camera directly - this will trigger iOS system permission prompt
      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          throw CameraException('no_cameras', 'No cameras available');
        }

        final controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        _controller = controller;
        await controller.initialize();
        
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      } catch (e) {
        // Continue to permission handling if camera init fails
      }

      // If camera initialization failed, check permission status
      var status = await Permission.camera.status;

      // Only show settings dialog if permanently denied
      if (status.isPermanentlyDenied) {
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Camera Permission Required'),
              content: const Text(
                'CardWizz needs camera access to scan cards.\n\n'
                'Please enable camera access in your device settings:\n'
                'Settings > CardWizz > Camera',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await openAppSettings();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Open Settings'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // If not permanently denied, try requesting permission
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      if (status.isGranted) {
        await _initializeCamera();
      } else {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_controller != null) {
      await _disposeCamera();
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_cameras', 'No cameras available');
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      _initializeControllerFuture = controller.initialize();
      await _initializeControllerFuture;

      // Calculate preview aspect ratio
      if (mounted) {
        final size = MediaQuery.of(context).size;
        _previewAspectRatio = size.width / size.height;
        
        // Set optimal preview size
        await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
        
        // Enable auto focus
        await _controller!.setFocusMode(FocusMode.auto);
        
        setState(() => _isLoading = false);
      }
    } catch (e) {
      throw CameraException('init_failed', 'Failed to initialize camera: $e');
    }
  }

  Future<void> _disposeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  Future<void> _scanImage() async {
    try {
      setState(() => _isSearching = true);
      
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      
      setState(() {
        _capturedImagePath = image.path;
      });

      // Add delay to allow user to see the captured image
      await Future.delayed(const Duration(milliseconds: 500));
      
      final cardData = await _scannerService.processCapturedImage(image.path);

      if (mounted) {
        setState(() {
          _isSearching = false;
          if (cardData != null) {
            _scannedCard = TcgCard.fromJson(cardData);
            LoggingService.debug('Found card: ${_scannedCard!.name} #${_scannedCard!.number}');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not identify card. Please try again.'),
                duration: Duration(seconds: 2),
              ),
            );
            _capturedImagePath = null;  // Clear the image on failure
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    if (_capturedImagePath != null) {
      return Stack(
        children: [
          Container(color: Colors.black),
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_capturedImagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.8;
        final cardHeight = maxWidth / cardAspectRatio;

        return Stack(
          children: [
            // Camera preview
            Transform.scale(
              scale: _calculatePreviewScale(),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1 / _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
            
            // Dark overlay with card cutout
            ClipPath(
              clipper: CardScannerClipper(
                cardWidth: maxWidth,
                cardHeight: cardHeight,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),

            // Card frame
            Center(
              child: Container(
                width: maxWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    ...cardCornerIndicators(maxWidth, cardHeight),
                    if (_isSearching)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Scanning animation
            if (!_isSearching)
              Center(
                child: SizedBox(
                  width: maxWidth,
                  height: cardHeight,
                  child: AnimatedBuilder(
                    animation: _animationController!,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ScanAnimationPainter(
                          progress: _animationController!.value,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _calculatePreviewScale() {
    if (_previewAspectRatio == null) return 1.0;
    
    final cameraDimensions = _controller!.value.previewSize!;
    final cameraAspectRatio = cameraDimensions.height / cameraDimensions.width;
    
    // Calculate scaling factor to fill screen while maintaining aspect ratio
    if (_previewAspectRatio! < cameraAspectRatio) {
      return _previewAspectRatio! / cameraAspectRatio;
    } else {
      return cameraAspectRatio / _previewAspectRatio!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to initialize camera')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          // Toolbar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildToolbar(),
          ),
          // Results overlay
          if (_scannedCard != null) _buildResultsOverlay(),
          // Capture button (only show if no results)
          if (_scannedCard == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: _buildCaptureButton(),
            ),
          // Loading overlay
          if (_isSearching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0),
          ],
          stops: const [0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.flash_off, color: Colors.white),
                onPressed: () async {
                  final FlashMode newMode = _controller!.value.flashMode == FlashMode.off
                      ? FlashMode.torch
                      : FlashMode.off;
                  await _controller!.setFlashMode(newMode);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.black.withOpacity(0),
          ],
          stops: const [0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(64, 64, 64, 32),
      child: ElevatedButton(
        onPressed: _scanImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner),
            SizedBox(width: 8),
            Text('Scan Card'),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsOverlay() {
    if (_scannedCard == null) return const SizedBox.shrink();

    // Format set info with null safety
    final setInfo = _scannedCard!.setName != null
        ? '${_scannedCard!.setName} - ${_scannedCard!.number}'
        : _scannedCard!.number ?? 'Unknown';
    
    final setTotal = _scannedCard!.setTotal != null 
        ? '/${_scannedCard!.setTotal}'
        : '';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _scannedCard!.imageUrl != null
                  ? Image.network(
                      _scannedCard!.imageUrl!,
                      width: 40,
                      height: 56,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.image, color: Colors.white),
              title: Text(
                _scannedCard!.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '$setInfo$setTotal',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _scannedCard = null),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/card-details',
                        arguments: _scannedCard,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 20),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/add-to-collection',
                        arguments: _scannedCard,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text('Add to Collection'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Corner indicator positions
  List<Widget> cardCornerIndicators(double width, double height) {
    const cornerSize = 30.0;
    final color = Colors.white.withOpacity(0.8);
    
    return [
      Positioned(
        left: -1,
        top: -1,
        child: SizedBox(
          width: cornerSize,
          height: cornerSize,
          child: CustomPaint(
            painter: CornerPainter(color: color),
          ),
        ),
      ),
      Positioned(
        right: -1,
        top: -1,
        child: Transform.rotate(
          angle: pi/2,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: CustomPaint(
              painter: CornerPainter(color: color),
            ),
          ),
        ),
      ),
      Positioned(
        left: -1,
        bottom: -1,
        child: Transform.rotate(
          angle: -pi/2,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: CustomPaint(
              painter: CornerPainter(color: color),
            ),
          ),
        ),
      ),
      Positioned(
        right: -1,
        bottom: -1,
        child: Transform.rotate(
          angle: pi,
          child: SizedBox(
            width: cornerSize,
            height: cornerSize,
            child: CustomPaint(
              painter: CornerPainter(color: color),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _animationController?.dispose();
    // ...rest of existing dispose code...
    super.dispose();
  }
}

// Add this new class for corner painting
class CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  CornerPainter({
    required this.color,
    this.strokeWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const length = 20.0;
    
    // Draw horizontal line
    canvas.drawLine(
      const Offset(0, 0),
      Offset(length, 0),
      paint,
    );
    
    // Draw vertical line
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, length),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

// Add new painter for corner highlights
class CornerHighlightPainter extends CustomPainter {
  final double progress;
  final Color color;

  CornerHighlightPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 * (1 - progress))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);

    final cornerSize = size.width * 0.2;
    final path = Path()
      ..moveTo(0, cornerSize)
      ..lineTo(0, 0)
      ..lineTo(cornerSize, 0);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(CornerHighlightPainter oldDelegate) => 
    progress != oldDelegate.progress;
}

class CardScannerClipper extends CustomClipper<Path> {
  final double cardWidth;
  final double cardHeight;

  CardScannerClipper({
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cardRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cardWidth,
      height: cardHeight,
    );

    path.addRRect(
      RRect.fromRectAndRadius(
        cardRect,
        const Radius.circular(16),
      ),
    );

    return Path.combine(
      PathOperation.difference,
      path,
      Path()..addRRect(RRect.fromRectAndRadius(
        cardRect,
        const Radius.circular(16),
      )),
    );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ScanAnimationPainter extends CustomPainter {
  final double progress;
  final Color color;

  ScanAnimationPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define a bright green scanner color
    const scannerColor = Color(0xFF00FF9B);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scannerColor.withOpacity(0),
          scannerColor.withOpacity(0.8),
          scannerColor.withOpacity(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;  // Slightly thicker line

    final y = size.height * progress;
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = scannerColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Draw glow
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      glowPaint,
    );

    // Draw main line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScanAnimationPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
