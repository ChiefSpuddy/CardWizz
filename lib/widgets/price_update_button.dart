import 'package:flutter/material.dart';

class PriceUpdateButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final DateTime? lastUpdateTime;

  const PriceUpdateButton({
    super.key,
    required this.isLoading,
    this.onPressed,
    this.lastUpdateTime,
  });

  @override
  State<PriceUpdateButton> createState() => _PriceUpdateButtonState();
}

class _PriceUpdateButtonState extends State<PriceUpdateButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _gradientPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500), // Slowed down for subtlety
      vsync: this,
    );

    _gradientPosition = Tween<double>(
      begin: -0.3,
      end: 1.3, // Reduced range for a more subtle effect
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastUpdateText = widget.lastUpdateTime != null 
        ? 'Updated ${_formatDateTime(widget.lastUpdateTime)}'
        : 'Never updated';

    return AnimatedBuilder(
      animation: _gradientPosition,
      builder: (context, child) {
        return Container(
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_gradientPosition.value, 0),
              end: Alignment.centerRight,
              colors: [
                // More subtle professional gradient
                const Color(0xFF43A047), // Darker green
                const Color(0xFF66BB6A), // Medium green
                const Color(0xFF43A047), // Back to darker green
              ],
              stops: const [0.1, 0.5, 0.9], // Adjust stops for smoother gradient
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Update Prices',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                lastUpdateText,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
