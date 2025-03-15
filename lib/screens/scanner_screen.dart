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

  // Add these new controller and variables
  late AnimationController _tipAnimationController;
  int _currentTipIndex = 0;
  bool _showTips = true;
  
  final List<Map<String, dynamic>> _scanningTips = [
    {
      'title': 'Center the Card',
      'description': 'Position the card within the frame for best results',
      'icon': Icons.crop_free,
    },
    {
      'title': 'Good Lighting',
      'description': 'Ensure the card is well-lit with no glare',
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'title': 'Hold Steady',
      'description': 'Keep your phone steady for a clear scan',
      'icon': Icons.pan_tool_outlined,
    },
    {
      'title': 'Scan Number',
      'description': 'Make sure the card number is visible',
      'icon': Icons.tag,
    },
  ];

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

    // Initialize tip animation controller
    _tipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Change tip every 5 seconds
    );
    
    _tipAnimationController.addListener(() {
      if (_tipAnimationController.status == AnimationStatus.completed) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _scanningTips.length;
          _tipAnimationController.reset();
          _tipAnimationController.forward();
        });
      }
    });

    // Start the scanning animation immediately
    _startScanningAnimation();
    _tipAnimationController.forward();
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
            
            // Add subtle tech grid overlay for futuristic feel
            Positioned.fill(
              child: CustomPaint(
                painter: TechGridPainter(
                  color: Colors.white.withOpacity(0.1),
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

            // Enhanced card frame with tech pattern
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
                    // Add subtle tech pattern inside frame
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.07,
                        child: CustomPaint(
                          painter: TechDetailsPainter(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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

            // Enhanced scanning animation
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
              
            // Add scanning tips in the top area
            if (_showTips)
              _buildScanningTips(),
            
          ],
        );
      },
    );
  }

  // Updated method to properly center scanning tips between app bar and scan grid
  Widget _buildScanningTips() {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Calculate the position dynamically to center between app bar and scan grid
    // App bar height + safe area + some padding
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = 56.0; // Standard app bar height
    final gridTopOffset = (MediaQuery.of(context).size.height / 2) - 200; // Approximate grid position
    
    // Position about 20% down from app bar (not exactly centered to bias toward top)
    final topPosition = topPadding + appBarHeight + ((gridTopOffset - appBarHeight - topPadding) * 0.2);
    
    return Positioned(
      top: topPosition,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _tipAnimationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _tipAnimationController,
                curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
                reverseCurve: const Interval(0.8, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -0.2),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _tipAnimationController,
                  curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.4), // More subtle border
                    width: 1.0, // Thinner border
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Reduced padding
                  child: Row(
                    children: [
                      // Smaller icon container
                      Container(
                        padding: const EdgeInsets.all(8), // Reduced padding
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.15),
                              colorScheme.primary.withOpacity(0.25),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _scanningTips[_currentTipIndex]['icon'],
                          color: colorScheme.primary,
                          size: 20, // Reduced from 24
                        ),
                      ),
                      const SizedBox(width: 10), // Reduced spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _scanningTips[_currentTipIndex]['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Reduced from 15
                                shadows: [
                                  Shadow(
                                    color: colorScheme.primary.withOpacity(0.4),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _scanningTips[_currentTipIndex]['description'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12, // Reduced from 13
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3), // Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 14), // Reduced icon size
                          onPressed: () => setState(() => _showTips = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 18, // Reduced from 20
                            minHeight: 18, // Reduced from 20
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Updated toolbar with more futuristic design
  Widget _buildToolbar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Enhanced back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'CARD SCANNER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: colorScheme.primary.withOpacity(0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Enhanced help button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _showTips ? Icons.help : Icons.help_outline, 
                    color: _showTips ? colorScheme.primary : Colors.white,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _showTips = !_showTips),
                  tooltip: 'Help',
                ),
              ),
              // Enhanced flash button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _controller?.value.flashMode == FlashMode.off
                        ? Icons.flash_off
                        : Icons.flash_on,
                    color: _controller?.value.flashMode == FlashMode.torch 
                        ? colorScheme.primary
                        : Colors.white,
                    size: 18,
                  ),
                  onPressed: () async {
                    if (_controller == null) return;
                    
                    final FlashMode newMode = _controller!.value.flashMode == FlashMode.off
                        ? FlashMode.torch
                        : FlashMode.off;
                    await _controller!.setFlashMode(newMode);
                    setState(() {});
                  },
                  tooltip: 'Flash',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Improved capture button with less bright design
  Widget _buildCaptureButton() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.4),
            Colors.transparent,
          ],
          stops: const [0.4, 0.8, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(64, 64, 64, 32),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          // Less bright gradient that's more muted with darker colors
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.7), // Reduced opacity
              colorScheme.secondary.withOpacity(0.7), // Reduced opacity
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(32),
          // Subtle pulsating animation effect
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3), // Reduced shadow opacity
              blurRadius: 12,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: colorScheme.secondary.withOpacity(0.3), // Reduced shadow opacity
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () {
              _animateScanButtonTap();
              _scanImage();
            },
            splashColor: Colors.white24,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Enhanced icon with glow effect
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.document_scanner,
                      color: Colors.white,
                      size: 24, // Slightly smaller than before
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'SCAN CARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Slightly smaller than before
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add a button pulse animation when tapped
  late final AnimationController _buttonAnimationController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  void _animateScanButtonTap() {
    _buttonAnimationController.forward(from: 0.0);
  }
  
  // Add a cool scan effect animation when scan is triggered
  Widget _buildScanEffect() {
    return AnimatedBuilder(
      animation: _buttonAnimationController,
      builder: (context, child) {
        return _buttonAnimationController.value > 0 
          ? Positioned.fill(
              child: CustomPaint(
                painter: ScanEffectPainter(
                  progress: _buttonAnimationController.value,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : const SizedBox.shrink();
      }
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
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize camera',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
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
          // Capture button - moved higher up from bottom:32 to bottom:80
          if (_scannedCard == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 80, // Moved up from original position (was 32)
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
          // Add scan effect animation
          _buildScanEffect(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _tipAnimationController.dispose();
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

// Enhanced scan animation painter for more futuristic look
class ScanAnimationPainter extends CustomPainter {
  final double progress;
  final Color color;

  ScanAnimationPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define a bright cyan scanner color but make it slightly less bright
    const scannerColor = Color(0xFF00DDEE); // Changed from 00F0FF to 00DDEE (less bright)

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scannerColor.withOpacity(0),
          scannerColor.withOpacity(0.8), // Reduced from 0.9
          scannerColor.withOpacity(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Reduced from 2.5

    final y = size.height * progress;
    
    // Add enhanced glow effect with reduced opacity
    final glowPaint = Paint()
      ..color = scannerColor.withOpacity(0.3) // Reduced from 0.4
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 // Reduced from 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // Reduced from 12
    
    final secondaryGlowPaint = Paint()
      ..color = scannerColor.withOpacity(0.15) // Reduced from 0.2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 // Reduced from 16
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14); // Reduced from 16

    // Draw secondary outer glow
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      secondaryGlowPaint,
    );
    
    // Draw main glow
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
    
    // Add subtle data points along scan line for tech effect
    final dotRadius = 1.5;
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final distance = size.width / 10;
    for (var i = 0; i < 10; i++) {
      // Only show some dots based on random-looking pattern
      if (i % 2 == 0 || i % 3 == 0) {
        canvas.drawCircle(
          Offset(i * distance, y),
          dotRadius,
          dotPaint,
        );
      }
    }
    
    // Draw small tech details along the scan line (more subtle)
    final detailPaint = Paint()
      ..color = scannerColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    // Left scanner detail
    canvas.drawRect(
      Rect.fromLTWH(0, y - 6, 4, 12), // Smaller rectangle
      detailPaint,
    );
    
    // Right scanner detail
    canvas.drawRect(
      Rect.fromLTWH(size.width - 4, y - 6, 4, 12), // Smaller rectangle
      detailPaint,
    );
    
    // Smaller center scanner circle
    canvas.drawCircle(
      Offset(size.width / 2, y),
      3, // Reduced from 4
      detailPaint,
    );
    
    // Add tech details with random-looking pattern
    final techPaint = Paint()
      ..color = scannerColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    // Add small tech measurement lines
    final measurementHeight = 4.0;
    for (int i = 1; i < 10; i++) {
      if (i % 3 == 0) {
        final xPos = size.width * (i / 10);
        canvas.drawLine(
          Offset(xPos, y - measurementHeight),
          Offset(xPos, y + measurementHeight),
          techPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ScanAnimationPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// Add new tech grid painter for futuristic feel
class TechGridPainter extends CustomPainter {
  final Color color;
  
  TechGridPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // Draw vertical lines
    const double spacing = 40.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(TechGridPainter oldDelegate) => color != oldDelegate.color;
}

// Add tech details painter for inside card frame
class TechDetailsPainter extends CustomPainter {
  final Color color;
  
  TechDetailsPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    
    // Draw some tech-looking details
    // Circuit patterns in corners
    final pathTopLeft = Path()
      ..moveTo(20, 10)
      ..lineTo(50, 10)
      ..moveTo(30, 10)
      ..lineTo(30, 30)
      ..lineTo(50, 30);
    canvas.drawPath(pathTopLeft, paint);
    
    final pathBottomRight = Path()
      ..moveTo(size.width - 20, size.height - 10)
      ..lineTo(size.width - 50, size.height - 10)
      ..moveTo(size.width - 30, size.height - 10)
      ..lineTo(size.width - 30, size.height - 30)
      ..lineTo(size.width - 50, size.height - 30);
    canvas.drawPath(pathBottomRight, paint);
    
    // Draw small target marks
    canvas.drawCircle(Offset(20, size.height - 20), 8, paint);
    canvas.drawCircle(Offset(20, size.height - 20), 3, paint);
    
    canvas.drawCircle(Offset(size.width - 20, 20), 8, paint);
    canvas.drawCircle(Offset(size.width - 20, 20), 3, paint);
  }
  
  @override
  bool shouldRepaint(TechDetailsPainter oldDelegate) => color != oldDelegate.color;
}

// New scan effect painter for cool animation when scan button is pressed
class ScanEffectPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  ScanEffectPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create an expanding circle from the center
    final paint = Paint()
      ..color = color.withOpacity((1 - progress) * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    final radius = size.width * 0.8 * progress;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
    
    // Add inner rings with different opacities
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius * 0.8,
      paint..color = color.withOpacity((1 - progress) * 0.3),
    );
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius * 0.6,
      paint..color = color.withOpacity((1 - progress) * 0.4),
    );
  }
  
  @override
  bool shouldRepaint(ScanEffectPainter oldDelegate) => 
      progress != oldDelegate.progress || 
      color != oldDelegate.color;
}
