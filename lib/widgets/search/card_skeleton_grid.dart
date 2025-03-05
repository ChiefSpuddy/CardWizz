import 'package:flutter/material.dart';
import 'dart:math' as math;

class CardSkeletonGrid extends StatefulWidget {
  final int itemCount;
  final String? setName;

  const CardSkeletonGrid({
    Key? key,
    this.itemCount = 12,
    this.setName,
  }) : super(key: key);

  @override
  State<CardSkeletonGrid> createState() => _CardSkeletonGridState();
}

class _CardSkeletonGridState extends State<CardSkeletonGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _CardSkeleton(
            controller: _shimmerController,
            // Vary card heights slightly for visual interest
            heightFactor: 0.95 + math.Random().nextDouble() * 0.1,
          ),
          childCount: widget.itemCount,
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final AnimationController controller;
  final double heightFactor;

  const _CardSkeleton({
    Key? key,
    required this.controller,
    this.heightFactor = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // Shimmer effect
                Positioned.fill(
                  child: FractionallySizedBox(
                    heightFactor: heightFactor,
                    widthFactor: 0.8,
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [baseColor, highlightColor, baseColor],
                          stops: const [0.0, 0.5, 1.0],
                          begin: const Alignment(-1.0, -0.3),
                          end: const Alignment(1.0, 0.3),
                          tileMode: TileMode.clamp,
                          transform: _SlidingGradientTransform(controller.value),
                        ).createShader(bounds);
                      },
                      child: Container(
                        color: baseColor,
                      ),
                    ),
                  ),
                ),
                
                // Bottom info area
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 10,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
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

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.value);

  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value, 0.0, 0.0);
  }
}
