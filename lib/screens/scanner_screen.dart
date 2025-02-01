import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scanner_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  late ScannerService _scannerService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerService = context.read<ScannerService>();
    _checkPermissionAndInitializeCamera();
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

      if (mounted) {
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
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final recognizedText = await _scannerService.recognizeText(image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recognized text: $recognizedText')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to scan image')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
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
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: ElevatedButton(
                onPressed: _scanImage,
                child: const Text('Scan'),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
