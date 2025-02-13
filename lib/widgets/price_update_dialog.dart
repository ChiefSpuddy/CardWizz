import 'package:flutter/material.dart';
import '../services/dialog_manager.dart';  // Make sure this import exists

// Change to StatefulWidget for better animation control
class PriceUpdateDialog extends StatefulWidget {
  final int current;
  final int total;
  final bool showProgressBar;

  const PriceUpdateDialog({
    super.key,
    required this.current,
    required this.total,
    this.showProgressBar = true,
  });

  @override
  State<PriceUpdateDialog> createState() => _PriceUpdateDialogState();
}

class _PriceUpdateDialogState extends State<PriceUpdateDialog> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _progressAnimation;  // Add this field

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize _progressAnimation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.current / widget.total,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        weight: 1,
        tween: ColorTween(
          begin: Colors.green.shade300,
          end: Colors.green.shade500,
        ),
      ),
      TweenSequenceItem(
        weight: 1,
        tween: ColorTween(
          begin: Colors.green.shade500,
          end: Colors.green.shade300,
        ),
      ),
    ]).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _progressController.repeat();
  }

  @override
  void didUpdateWidget(PriceUpdateDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.total != widget.total) {
      final progress = widget.total > 0 ? widget.current / widget.total : 0.0;
      _progressAnimation = Tween<double>(
        begin: _progressController.value,
        end: progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOut, // Changed to easeOut
      ));
      
      _progressController.forward(from: _progressController.value);
    }
  }

  void _updateProgress() {
    final progress = widget.total > 0 ? widget.current / widget.total : 0.0;
    _progressAnimation = Tween<double>(
      begin: _progressController.value,
      end: progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward(from: 0);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: DialogManager.instance.dialogUpdates,  // Now DialogManager is properly imported
      builder: (context, _) {
        final progress = widget.total > 0 ? widget.current / widget.total : 0.0;
        final percentage = (progress * 100).toInt();
        final isComplete = widget.current >= widget.total;
        
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isComplete) ...[
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 2 * 3.14159,
                        child: const Icon(Icons.sync, size: 48, color: Colors.green),
                      );
                    },
                  ),
                ] else ...[
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + (0.2 * value),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: value,
                          child: const Icon(
                            Icons.check_circle,
                            size: 48,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  isComplete ? 'Update Complete!' : 'Updating Card Prices',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isComplete) ...[
                  AnimatedBuilder(
                    animation: _colorAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 12, // Increased height
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              _colorAnimation.value ?? Colors.green,
                              Colors.green.shade500,
                              _colorAnimation.value ?? Colors.green,
                            ],
                            stops: [0.0, _glowAnimation.value, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _progressAnimation.value,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.5),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Add card name display
                  Text(
                    'Processing card ${widget.current} of ${widget.total}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check),
                    label: const Text('Done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
