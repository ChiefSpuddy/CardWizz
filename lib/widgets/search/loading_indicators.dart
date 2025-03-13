import 'package:flutter/material.dart';
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
