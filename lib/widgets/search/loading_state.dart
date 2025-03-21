import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'dart:math' as math;

class CardSkeletonGrid extends StatelessWidget {
  final int itemCount;
  final String? setName;
  final int crossAxisCount;
  final int delayFactor;
  final bool useShimmer;

  const CardSkeletonGrid({
    Key? key,
    required this.itemCount,
    this.setName,
    this.crossAxisCount = 3,
    this.delayFactor = 100,
    this.useShimmer = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Set name section with improved styling
          if (setName != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.style, 
                    size: 20, 
                    color: colorScheme.primary
                  ),
                  const SizedBox(width: 8),
                  Text(
                    setName!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
          // Improved loading message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading cards, please wait...',
                  style: TextStyle(
                    color: colorScheme.onBackground.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Enhanced skeleton cards grid with staggered animation
          Container(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // Use staggered delays for a wave-like animation effect
                final delay = (index % (crossAxisCount * 2)) * delayFactor;
                return ModernCardSkeleton(
                  delay: Duration(milliseconds: delay),
                  useShimmer: useShimmer,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// New improved card skeleton with modern animation
class ModernCardSkeleton extends StatefulWidget {
  final Duration delay;
  final bool useShimmer;

  const ModernCardSkeleton({
    Key? key,
    this.delay = Duration.zero,
    this.useShimmer = true,
  }) : super(key: key);

  @override
  State<ModernCardSkeleton> createState() => _ModernCardSkeletonState();
}

class _ModernCardSkeletonState extends State<ModernCardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardElevationAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Multiple animations for different effects
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _cardScaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    _cardElevationAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
      ),
    );
    
    if (widget.useShimmer) {
      _controller.repeat(reverse: false);
    } else {
      _controller.forward();
    }
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get background colors based on theme
    final cardBaseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
    final cardHighlightColor = isDark ? Colors.grey.shade700 : Colors.white;
    final shimmerBaseColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final shimmerHighlightColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardBaseColor,
                  cardHighlightColor,
                  cardBaseColor,
                ],
                stops: const [0.1, 0.3, 0.5],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05 * _cardElevationAnimation.value),
                  blurRadius: 8 * _cardElevationAnimation.value,
                  spreadRadius: 1 * _cardElevationAnimation.value,
                  offset: Offset(0, 2 * _cardElevationAnimation.value),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Card content with modern skeleton look
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image area with subtle gradient
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                shimmerBaseColor,
                                shimmerHighlightColor,
                                shimmerBaseColor,
                              ],
                              stops: const [0.1, 0.5, 0.9],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.catching_pokemon,
                              size: 32,
                              color: isDark 
                                  ? Colors.grey.shade600 
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      
                      // Card info area with animated skeleton elements
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Animated title skeleton
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: shimmerBaseColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Animated details skeletons
                            Row(
                              children: [
                                // Type/set indicator
                                Container(
                                  height: 10,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: shimmerBaseColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Spacer(),
                                
                                // Price indicator
                                Container(
                                  height: 10,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: shimmerBaseColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Enhanced shimmer effect
                  if (widget.useShimmer)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(_shimmerAnimation.value, 0),
                            end: Alignment(_shimmerAnimation.value + 0.8, 1),
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.05),
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Keep the original CardSkeleton for backwards compatibility
class CardSkeleton extends StatefulWidget {
  final Duration delay;
  final bool useShimmer;

  const CardSkeleton({
    Key? key,
    this.delay = Duration.zero,
    this.useShimmer = true,
  }) : super(key: key);

  @override
  State<CardSkeleton> createState() => _CardSkeletonState();
}

class _CardSkeletonState extends State<CardSkeleton> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    // Delegate to the new modern skeleton for improved appearance
    return ModernCardSkeleton(
      delay: widget.delay,
      useShimmer: widget.useShimmer,
    );
  }
}
