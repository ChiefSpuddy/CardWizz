import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedBackground extends StatelessWidget {
  final Widget child;
  
  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.3, // Increased from 0.1
            child: Lottie.asset(
              'assets/animations/background.json',
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
