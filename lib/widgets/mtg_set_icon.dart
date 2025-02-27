import 'package:flutter/material.dart';
import 'dart:math' as math;

class MtgSetIcon extends StatelessWidget {
  final String setCode;
  final double size;
  final Color? color;

  const MtgSetIcon({
    Key? key,
    required this.setCode,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get a consistent color based on setCode
    final int colorValue = setCode.hashCode;
    final Color setColor = color ?? Color(colorValue).withOpacity(1.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Use gradient for better visual appearance
        gradient: LinearGradient(
          colors: [
            setColor.withOpacity(0.8),
            setColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 5),
        border: Border.all(
          color: setColor.withOpacity(0.9),
          width: 1.5,
        ),
        // Add shadow for better visuals
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          // Make sure to handle empty codes gracefully
          setCode.isEmpty ? '?' : setCode.toUpperCase().substring(0, math.min(3, setCode.length)),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
