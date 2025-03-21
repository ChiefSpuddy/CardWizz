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
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Set name section
          if (setName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.style, 
                    size: 20, 
                    color: Theme.of(context).colorScheme.primary
                  ),
                  const SizedBox(width: 8),
                  Text(
                    setName!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
          // Waiting for results message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Loading cards, please wait...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ),
          
          // Skeleton cards grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final delay = (index % (itemCount / 2)).toInt() * delayFactor;
              return CardSkeleton(
                delay: Duration(milliseconds: delay),
                useShimmer: useShimmer,
              );
            },
          ),
        ],
      ),
    );
  }
}

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
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    if (widget.useShimmer) {
      _controller.repeat(reverse: true);
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
      return Container(color: Colors.transparent);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.searchBarDark.withOpacity(0.8) 
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Main card area
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image area
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: isDark 
                            ? Colors.grey.shade800.withOpacity(0.8) 
                            : Colors.grey.shade300,
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    
                    // Title area
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.grey.shade700.withOpacity(0.5) 
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.grey.shade700.withOpacity(0.4) 
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                height: 10,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.grey.shade700.withOpacity(0.4) 
                                      : Colors.grey.shade300,
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
                
                // Shimmer overlay
                if (widget.useShimmer)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(_animation.value * 0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
