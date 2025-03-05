import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CardCollectedAnimation extends StatelessWidget {
  const CardCollectedAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti animation
        Lottie.asset(
          'assets/animations/confetti.json',
          fit: BoxFit.cover,
        ),
        // Success checkmark
        Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
