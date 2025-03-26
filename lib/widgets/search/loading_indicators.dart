import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shimmer/shimmer.dart'; // Add this package to your pubspec.yaml
import '../../constants/app_colors.dart';  // Add this import for AppColors

class LoadingMoreIndicator extends StatelessWidget {
  const LoadingMoreIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class ShimmerLoadingCard extends StatefulWidget {
  const ShimmerLoadingCard({Key? key}) : super(key: key);

  @override
  State<ShimmerLoadingCard> createState() => _ShimmerLoadingCardState();
}

class _ShimmerLoadingCardState extends State<ShimmerLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark 
        ? const Color(0xFF2C2C2C) 
        : const Color(0xFFE8E8E8);
    final highlightColor = isDark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value * 3.14),
            ),
          ),
        );
      },
    );
  }
}

class SearchLoadingIndicator extends StatelessWidget {
  final double size;
  
  const SearchLoadingIndicator({
    Key? key,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size / 10,
        valueColor: AlwaysStoppedAnimation<Color>(
          isDark ? AppColors.accentLight : AppColors.accentDark,
        ),
      ),
    );
  }
}

class PaginationLoadingIndicator extends StatelessWidget {
  const PaginationLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SearchLoadingIndicator(size: 24),
          SizedBox(width: 16),
          Text('Loading more cards...'),
        ],
      ),
    );
  }
}

class CardSkeletonGrid extends StatelessWidget {
  final int itemCount;
  final String? setName;

  const CardSkeletonGrid({
    Key? key,
    this.itemCount = 9,
    this.setName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Add variety to the skeletons
            final randomHeight = 0.7 + math.Random().nextDouble() * 0.3;
            
            return Shimmer.fromColors(
              baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card image skeleton
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8.0),
                          ),
                        ),
                        // Add a subtle hint about what's loading
                        child: setName != null ? Center(
                          child: Text(
                            setName!,
                            style: TextStyle(
                              color: isDark ? Colors.white12 : Colors.black12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ) : null,
                      ),
                    ),
                    
                    // Info section skeleton
                    Container(
                      height: 36,
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title line
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Price and number line
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Number
                              Container(
                                height: 8,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                              
                              // Price
                              Container(
                                height: 8,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }
}

class LoadingProgressIndicator extends StatelessWidget {
  final double progress;
  final String? message;
  
  const LoadingProgressIndicator({
    Key? key, 
    this.progress = 0.0,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 3,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
