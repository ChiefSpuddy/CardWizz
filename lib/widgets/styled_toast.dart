import 'package:flutter/material.dart';

class StyledToast extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;  
  final String? actionLabel;  
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final VoidCallback? onActionPressed; 
  final bool compact; // Add compact mode option

  const StyledToast({
    Key? key,
    required this.title,
    this.subtitle = '',  
    this.icon,  
    this.actionLabel,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.onTap,
    this.onAction,
    this.onActionPressed,
    this.compact = false, // Default to standard size
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final txtColor = textColor ?? Colors.white;
    final icnColor = iconColor ?? txtColor;
    final actionCallback = onAction ?? onActionPressed;

    return Material(
      elevation: compact ? 4 : 6,
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 8 : 12,
            ),
            child: Row(
              children: [
                if (icon != null)  
                  Container(
                    padding: EdgeInsets.all(compact ? 8 : 10),
                    decoration: BoxDecoration(
                      color: icnColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: icnColor,
                      size: compact ? 18 : 24,
                    ),
                  ),
                if (icon != null)  
                  SizedBox(width: compact ? 10 : 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: txtColor,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: compact ? 1 : 2),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: compact ? 12 : 14,
                              color: txtColor.withOpacity(0.8),
                            ),
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (actionLabel != null && actionCallback != null) 
                  TextButton(
                    onPressed: actionCallback,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 12,
                        vertical: compact ? 4 : 6,
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        color: txtColor,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 12 : 14,
                      ),
                    ),
                  )
                else  
                  Icon(
                    Icons.chevron_right,
                    color: txtColor.withOpacity(0.7),
                    size: compact ? 18 : 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A completely new overlay-based toast implementation that doesn't use Modal Bottom Sheet
/// This avoids all navigation issues by using an Overlay entry instead
void showToast({
  required BuildContext context,
  required String title,
  required String subtitle,
  required IconData icon,
  bool isError = false,
  Duration duration = const Duration(seconds: 3),
  Color? backgroundColor,
  bool compact = false,
  int? durationSeconds,
  double? bottomOffset,  // Added parameter for positioning from bottom
  bool fromBottom = false, // Whether to display from bottom
  VoidCallback? onTap,   // Add onTap parameter
}) {
  // Skip showing toasts for search-related messages
  if (title.contains('No Cards Found') || 
      title.contains('Search Failed') ||
      subtitle.contains('search') ||
      subtitle.contains('Search')) {
    // Just log silently and return without showing anything
    print('Skipping search-related toast: $title - $subtitle');
    return;
  }
  
  // For all non-search related toasts, continue with normal behavior
  final overlay = Overlay.of(context);
  
  // Calculate position
  double topPosition = MediaQuery.of(context).padding.top + 16;
  
  // We need to declare the variable separately from its initialization
  // to avoid the "variable referenced before declaration" error
  late final OverlayEntry entryRef;
  
  entryRef = OverlayEntry(
    builder: (context) => Positioned(
      // Position based on fromBottom parameter
      top: fromBottom || bottomOffset != null ? null : (MediaQuery.of(context).padding.top + 16),
      bottom: fromBottom || bottomOffset != null ? (bottomOffset ?? 32) : null,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: ToastWidget(
          title: title,
          subtitle: subtitle,
          icon: icon,
          isError: isError,
          customOnTap: onTap,  // Pass the onTap callback
          fromBottom: fromBottom || bottomOffset != null, // Pass this to toast widget
          onDismiss: () {
            if (entryRef.mounted) {
              entryRef.remove();
            }
          },
        ),
      ),
    ),
  );
  
  // Insert the overlay entry
  overlay.insert(entryRef);
  
  // Use durationSeconds if provided, otherwise use the duration parameter
  final finalDuration = durationSeconds != null 
      ? Duration(seconds: durationSeconds) 
      : duration;
  
  // Remove the toast after the duration
  Future.delayed(finalDuration, () {
    if (entryRef.mounted) {
      entryRef.remove();
    }
  });
}

class ToastWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isError;
  final bool fromBottom; // Add this parameter
  final VoidCallback onDismiss;
  final VoidCallback? customOnTap;  // Add custom onTap callback
  
  const ToastWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isError = false,
    this.fromBottom = false, // Default to false for backward compatibility
    required this.onDismiss,
    this.customOnTap,  // Make it optional
  }) : super(key: key);

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // CRITICAL FIX: For bottom animation, we need to START at a positive offset
        // and move UP to zero, rather than the other way around
        final double startOffsetY = widget.fromBottom ? 50.0 : -50.0;
        final double endOffsetY = 0.0;
        
        // Calculate current offset based on animation value
        final double currentOffsetY = startOffsetY * (1.0 - _animation.value);
        
        return Transform.translate(
          offset: Offset(0, currentOffsetY),
          child: Opacity(
            opacity: _animation.value,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.customOnTap ?? () {
                    _controller.reverse().then((value) {
                      widget.onDismiss();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.isError 
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.isError ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _controller.reverse().then((value) {
                              widget.onDismiss();
                            });
                          },
                        ),
                      ],
                    ),
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
