import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late AnimationController _animationController;
  // Add new animation for scale effect
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Add bounce animation for more fun
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOutBack),
        reverseCurve: Interval(0.5, 1.0, curve: Curves.easeInBack),
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
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final gradientColors = widget.gradientColors.length >= 3
            ? [
                widget.gradientColors[0],
                widget.gradientColors[1],
                widget.gradientColors[2],
                widget.gradientColors[1],
                widget.gradientColors[0],
              ]
            : widget.gradientColors;
            
        return Transform.scale(
          // Add slight scale effect for more interactive feel
          scale: _isPressed ? 0.97 : 1.0,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                colors: gradientColors,
                stops: [
                  0,
                  0.25 + (_animationController.value * 0.2),
                  0.5,
                  0.75 - (_animationController.value * 0.2),
                  1,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: widget.addShadow ? [
                BoxShadow(
                  color: widget.gradientColors.first.withOpacity(_isPressed ? 0.2 : 0.3),
                  blurRadius: _isPressed ? 6 : 12, // Smaller shadow when pressed
                  spreadRadius: _isPressed ? 0 : 1,
                  offset: _isPressed 
                    ? const Offset(0, 2)  // Smaller offset when pressed
                    : const Offset(0, 6),
                ),
              ] : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: Colors.white.withOpacity(0.2),
                onTap: widget.isLoading ? null : () {
                  // Add haptic feedback for better UX
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
                              const SizedBox(width: 10), // Reduced from 12
                            ],
                            Text(
                              widget.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Reduced from 18
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
