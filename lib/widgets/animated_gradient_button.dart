import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class AnimatedGradientButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final List<Color> gradientColors;
  final double height;
  final double borderRadius;
  final bool addShadow;

  const AnimatedGradientButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.gradientColors = const [
      Color(0xFF6366F1),  // primary
      Color(0xFF818CF8),  // secondary
      Color(0xFF14B8A6),  // tertiary
    ],
    this.height = 60.0,
    this.borderRadius = 30.0,
    this.addShadow = true,
  }) : super(key: key);

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = widget.gradientColors.length >= 3
        ? widget.gradientColors
        : [...widget.gradientColors, ...widget.gradientColors.reversed];
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Scale effect has two components:
        // 1. Interactive press effect
        // 2. Subtle continuous pulse animation
        final scale = _isPressed 
            ? 0.97 // More noticeable press effect
            : 1.0 + (_animationController.value * 0.01); // Very subtle pulse
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                // Animated gradient position
                stops: [
                  0,
                  0.3 + (_animationController.value * 0.1),
                  0.7 - (_animationController.value * 0.1),
                  1.0,
                ],
              ),
              boxShadow: widget.addShadow ? [
                // Regular shadow
                BoxShadow(
                  color: widget.gradientColors.first.withOpacity(_isPressed ? 0.2 : 0.3),
                  blurRadius: _isPressed ? 6 : 10,
                  spreadRadius: _isPressed ? 0 : 2,
                  offset: _isPressed 
                    ? const Offset(0, 2)
                    : const Offset(0, 4),
                ),
                // Add a subtle glow effect
                BoxShadow(
                  color: widget.gradientColors.last.withOpacity(0.05 + (_animationController.value * 0.05)),
                  blurRadius: 15 + (_animationController.value * 5),
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
              ] : null,
            ),
            child: CustomPaint(
              painter: _isPressed ? PressEffectPainter() : null,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  splashColor: Colors.white.withOpacity(0.15),
                  highlightColor: Colors.white.withOpacity(0.1),
                  onTap: widget.isLoading ? null : () {
                    HapticFeedback.mediumImpact();
                    widget.onPressed();
                  },
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                widget.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    )
                                  ]
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

// Add a subtle radial effect when pressed
class PressEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const double spreadSize = 0.8;

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: spreadSize,
      colors: [
        Colors.black.withOpacity(0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.darken;

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
