import 'package:flutter/material.dart';
import '../services/logging_service.dart';
import '../utils/color_extensions.dart';

/// Shows a styled toast notification with customizable appearance
void showToast({
  required BuildContext context,
  required String title,
  String? subtitle,
  IconData? icon,
  bool isError = false,
  bool compact = false,
  Duration duration = const Duration(seconds: 3),
}) {
  // Create and show a toast overlay
  final overlay = StyledToastOverlay(
    title: title,
    subtitle: subtitle,
    icon: icon,
    isError: isError,
    compact: compact,
    duration: duration,
  );
  
  // Use Overlay to display the toast
  Overlay.of(context).insert(overlay);
}

class StyledToastOverlay extends OverlayEntry {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isError;
  final bool compact;
  final Duration duration;
  
  StyledToastOverlay({
    required this.title,
    this.subtitle,
    this.icon,
    this.isError = false,
    this.compact = false,
    this.duration = const Duration(seconds: 3),
  }) : super(
    builder: (BuildContext context) {
      return StyledToastWidget(
        title: title,
        subtitle: subtitle,
        icon: icon,
        isError: isError,
        compact: compact,
        duration: duration,
        onClose: () => _removeOverlay(context),
      );
    },
  );
  
  static void _removeOverlay(BuildContext context) {
    // Nothing to do here, the toast removes itself
  }
}

class StyledToastWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isError;
  final bool compact;
  final Duration duration;
  final VoidCallback onClose;
  
  const StyledToastWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.isError,
    required this.compact,
    required this.duration,
    required this.onClose,
  }) : super(key: key);
  
  @override
  State<StyledToastWidget> createState() => _StyledToastWidgetState();
}

class _StyledToastWidgetState extends State<StyledToastWidget> with SingleTickerProviderStateMixin {
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
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    
    // Show animation
    _controller.forward();
    
    // Schedule dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onClose();
      // Remove this overlay entry
      if (mounted) {
        final overlayState = Overlay.of(context);
        for (final entry in overlayState.mounted ? <OverlayEntry>[] : <OverlayEntry>[]) {
          if (entry is StyledToastOverlay) {
            entry.remove();
            break;
          }
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Calculate toast appearance based on error state and theme
    final backgroundColor = widget.isError
        ? colorScheme.error
        : (isDark
            ? colorScheme.surface.withAlpha((0.9 * 255).round()) // Fixed: Using withAlpha instead of withOpacity
            : colorScheme.primary);
    
    final foregroundColor = widget.isError || !isDark
        ? Colors.white
        : colorScheme.onSurface;
    
    // Set default icon based on toast type
    final displayIcon = widget.icon ?? (widget.isError ? Icons.error_outline : Icons.check_circle_outline);
    
    // Determine the top position
    final safeAreaTop = MediaQuery.of(context).padding.top;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_animation),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: InkWell(
                    onTap: _dismiss,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: widget.compact ? null : double.infinity,
                      padding: widget.compact
                          ? const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
                          : const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).round()), // Fixed: Using withAlpha
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
                        children: [
                          Icon(
                            displayIcon,
                            color: foregroundColor,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: foregroundColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      color: foregroundColor.withAlpha((0.8 * 255).round()), // Fixed: Using withAlpha
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!widget.compact) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.close,
                              color: foregroundColor.withAlpha((0.7 * 255).round()), // Fixed: Using withAlpha
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a toast notification at the specified position
void showPositionedToast({
  required BuildContext context,
  required String message,
  IconData? icon,
  bool isError = false,
  Alignment alignment = Alignment.bottomCenter,
  Duration duration = const Duration(seconds: 2),
}) {
  // Create toast overlay and calculate position
  final overlay = StyledPositionedToastOverlay(
    message: message,
    icon: icon,
    isError: isError,
    alignment: alignment,
    duration: duration,
  );
  
  // Use Overlay to display the toast
  Overlay.of(context).insert(overlay);
  
  // Log for debugging - replaced with LoggingService
  LoggingService.debug('Showing positioned toast: $message');
}

class StyledPositionedToastOverlay extends OverlayEntry {
  final String message;
  final IconData? icon;
  final bool isError;
  final Alignment alignment;
  final Duration duration;
  
  StyledPositionedToastOverlay({
    required this.message,
    this.icon,
    this.isError = false,
    required this.alignment,
    this.duration = const Duration(seconds: 2),
  }) : super(
    builder: (BuildContext context) {
      return StyledPositionedToastWidget(
        message: message,
        icon: icon,
        isError: isError,
        alignment: alignment,
        duration: duration,
        onClose: () {
          // Handled internally
        },
      );
    },
  );
}

class StyledPositionedToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final bool isError;
  final Alignment alignment;
  final Duration duration;
  final VoidCallback onClose;
  
  const StyledPositionedToastWidget({
    Key? key,
    required this.message,
    this.icon,
    this.isError = false,
    required this.alignment,
    required this.duration,
    required this.onClose,
  }) : super(key: key);
  
  @override
  State<StyledPositionedToastWidget> createState() => _StyledPositionedToastWidgetState();
}

class _StyledPositionedToastWidgetState extends State<StyledPositionedToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  // Define constants for more clarity
  static const double startOffsetY = 20.0;
  // Removed unused variable endOffsetY
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    
    // Show animation
    _controller.forward();
    
    // Schedule dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onClose();
      // Remove this overlay entry
      if (mounted) {
        final overlayState = Overlay.of(context);
        final entry = ModalRoute.of(context)?.overlayEntries.last;
        if (entry != null && entry is StyledPositionedToastOverlay) {
          entry.remove();
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Calculate toast appearance
    final backgroundColor = widget.isError
        ? colorScheme.error.withAlpha((0.9 * 255).round()) // Fixed: Using withAlpha
        : (isDark
            ? Colors.grey[800]!
            : colorScheme.primary.withAlpha((0.9 * 255).round())); // Fixed: Using withAlpha
    
    final foregroundColor = Colors.white;
    
    // Get default icon based on type
    final displayIcon = widget.icon ?? (widget.isError ? Icons.error_outline : Icons.check_circle_outline);
    
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(32),
          alignment: widget.alignment,
          child: FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: _getSlideOffset(),
                end: Offset.zero,
              ).animate(_animation),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        displayIcon,
                        color: foregroundColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: foregroundColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Offset _getSlideOffset() {
    // Return appropriate offset based on alignment
    if (widget.alignment == Alignment.bottomCenter) {
      return const Offset(0, startOffsetY / 100);
    } else if (widget.alignment == Alignment.topCenter) {
      return const Offset(0, -startOffsetY / 100);
    } else if (widget.alignment == Alignment.centerLeft) {
      return const Offset(-startOffsetY / 100, 0);
    } else if (widget.alignment == Alignment.centerRight) {
      return const Offset(startOffsetY / 100, 0);
    }
    return Offset.zero;
  }
}
