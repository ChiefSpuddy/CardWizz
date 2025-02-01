import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _splashController;
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style for splash screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _splashController = AnimationController(
      duration: const Duration(seconds: 5), // Increased duration to 5 seconds
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _splashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Restore system UI overlay
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    _loadingController.dispose();
    // Ensure system UI is restored when disposing
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Main splash animation
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/SplashAnimation.json',
              controller: _splashController,
              width: size.width,
              height: size.height,
              fit: BoxFit.cover,
              onLoaded: (composition) {
                _splashController.forward();
              },
            ),
          ),
          // Loading animation overlay
          Center(
            child: SizedBox(
              width: 100, // Adjust size as needed
              height: 100,
              child: Lottie.asset(
                'assets/animations/Loading.json',
                controller: _loadingController,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}