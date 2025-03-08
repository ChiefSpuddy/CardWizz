import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingScreen extends StatelessWidget {
  final double progress;
  final String message;
  
  const LoadingScreen({
    Key? key,
    this.progress = 0.0,
    this.message = 'Loading...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.height < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Beautiful animation
                SizedBox(
                  height: isSmallScreen ? 140 : 180,
                  width: isSmallScreen ? 140 : 180,
                  child: _buildLoadingAnimation(context),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                const Text(
                  'CardWizz',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 40),
                
                // Progress indicator
                SizedBox(
                  width: screenSize.width * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Linear progress indicator with larger height
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress > 0 ? progress : null,
                          minHeight: 10,
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Message
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Try different animation files in case one is missing
  Widget _buildLoadingAnimation(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          // First try our custom card animation
          return Lottie.asset(
            'assets/animations/card_loading.json',
            fit: BoxFit.contain,
            repeat: true,
            reverse: false,
            animate: true,
          );
        } catch (e) {
          try {
            // Then try the generic loading animation
            return Lottie.asset(
              'assets/animations/Loading.json',
              fit: BoxFit.contain,
              repeat: true,
            );
          } catch (e2) {
            try {
              // Try another animation as fallback
              return Lottie.asset(
                'assets/animations/SplashAnimation.json',
                fit: BoxFit.contain,
                repeat: true,
              );
            } catch (e3) {
              // Last resort: use a beautiful animated spinner
              return _buildFallbackAnimation(context);
            }
          }
        }
      },
    );
  }

  // Fallback animation if no Lottie animations are available
  Widget _buildFallbackAnimation(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 2 * 3.14159), // One full rotation
      duration: const Duration(seconds: 2),
      builder: (context, double value, child) {
        return Transform.rotate(
          angle: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'CW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      // Restart the animation when done
      onEnd: () => setState(() {}),
    );
  }

  // Helper method to trigger rebuild when animation ends
  void setState(VoidCallback fn) {
    fn();
  }
}
