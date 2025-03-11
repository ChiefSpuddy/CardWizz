import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color? particleColor;
  final double maxParticleSize;
  final Color? color; // Add color parameter
  
  const AnimatedBackground({
    super.key,
    required this.child,
    this.particleCount = 20,
    this.particleColor,
    this.maxParticleSize = 4.0,
    this.color, // Make this optional
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 2), // Long duration for continuous animation
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeParticles();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _initializeParticles() {
    final size = MediaQuery.of(context).size;
    
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        _Particle(
          size.width * _random.nextDouble(),
          size.height * _random.nextDouble(),
          1 + _random.nextDouble() * (widget.maxParticleSize - 1.0),
          0.2 + _random.nextDouble() * 0.8, // opacity
          0.3 + _random.nextDouble() * 0.7, // speed
          _random.nextDouble() * 2 * math.pi, // direction
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.particleColor ?? Theme.of(context).primaryColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Use provided color or default based on theme
    final backgroundColor = widget.color ?? (isDarkMode 
        ? Colors.grey[900] // Darker background for dark mode
        : const Color(0xFFEEF6FF)); // Light blue for light mode
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient background
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            // Only use the gradient in light mode unless color is explicitly provided
            gradient: widget.color == null && !isDarkMode ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight.add(Alignment(
                math.sin(_controller.value * 2 * math.pi) * 0.2,
                math.cos(_controller.value * 2 * math.pi) * 0.2,
              )),
              colors: [
                const Color(0xFFEEF6FF),
                const Color(0xFFE3F2FF),
                const Color(0xFFD6EBFF),
              ],
              stops: const [0.0, 0.5, 1.0],
            ) : null,
          ),
        ),
        
        // Animated particles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                animation: _controller.value,
                color: color,
              ),
            );
          },
        ),
          
        // Content
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double opacity;
  double speed;
  double direction;
  
  _Particle(
    this.x,
    this.y,
    this.size,
    this.opacity,
    this.speed,
    this.direction,
  );
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animation;
  final Color color;
  
  _ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    
    for (var particle in particles) {
      // Update position based on animation
      final updatedX = (particle.x + math.cos(particle.direction) * particle.speed * animation * 50) % size.width;
      final updatedY = (particle.y + math.sin(particle.direction) * particle.speed * animation * 50) % size.height;
      
      paint.color = color.withOpacity(particle.opacity);
      canvas.drawCircle(Offset(updatedX, updatedY), particle.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
