import 'package:flutter/material.dart';
import 'dart:async';

enum NotificationPosition {
  top,
  bottom,
  center
}

class NotificationManager {
  static final List<OverlayEntry> _activeNotifications = [];
  static const int _maxNotifications = 3;
  
  /// Shows a notification with the given parameters.
  static void show(
    BuildContext context, {
    String? title,
    required String message,
    IconData icon = Icons.notifications,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    NotificationPosition position = NotificationPosition.top,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onAction,
    bool preventNavigation = false,
    bool compact = false,
  }) {
    // Remove old notifications if we have too many
    if (_activeNotifications.length >= _maxNotifications) {
      _activeNotifications.first.remove();
      _activeNotifications.removeAt(0);
    }

    final notification = _createNotification(
      context,
      title: title,
      message: message,
      icon: icon,
      isError: isError,
      duration: duration,
      onTap: onTap,
      position: position,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed ?? onAction,
      compact: compact,
    );
    
    Overlay.of(context).insert(notification);
    _activeNotifications.add(notification);
    
    // Auto-dismiss after duration
    Timer(duration, () {
      if (_activeNotifications.contains(notification)) {
        notification.remove();
        _activeNotifications.remove(notification);
      }
    });
  }
  
  /// Shows a success notification
  static void success(
    BuildContext context, {
    String? title,
    required String message,
    IconData icon = Icons.check_circle,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    NotificationPosition position = NotificationPosition.top,
    bool preventNavigation = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    show(
      context,
      title: title ?? 'Success',
      message: message,
      icon: icon,
      isError: false,
      duration: duration,
      onTap: onTap,
      position: position,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      onAction: onAction,
      preventNavigation: preventNavigation,
      compact: compact,
    );
  }
  
  /// Shows an error notification
  static void error(
    BuildContext context, {
    String? title,
    required String message,
    IconData icon = Icons.error_outline,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    NotificationPosition position = NotificationPosition.top,
    bool preventNavigation = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
    VoidCallback? onAction,
    bool compact = false,
  }) {
    show(
      context,
      title: title ?? 'Error',
      message: message,
      icon: icon,
      isError: true,
      duration: duration,
      onTap: onTap,
      position: position,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      onAction: onAction,
      preventNavigation: preventNavigation,
      compact: compact,
    );
  }
  
  /// Creates and returns an overlay entry for the notification
  static OverlayEntry _createNotification(
    BuildContext context, {
    String? title,
    required String message,
    IconData icon = Icons.notifications,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    NotificationPosition position = NotificationPosition.top,
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool compact = false,
  }) {
    // Get the theme and screen size
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Define gradient colors based on notification type
    final List<Color> gradientColors = isError
        ? [
            Colors.red.shade700, 
            Colors.red.shade900,
          ]
        : [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ];

    // Notification entry creation
    return OverlayEntry(
      builder: (context) {
        return SafeArea(
          minimum: EdgeInsets.only(
            top: position == NotificationPosition.top ? _activeNotifications.length * 4.0 : 0,
            bottom: position == NotificationPosition.bottom ? _activeNotifications.length * 4.0 : 0,
            left: compact ? 8.0 : 16.0,
            right: compact ? 8.0 : 16.0,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Align(
              alignment: position == NotificationPosition.top 
                  ? Alignment.topCenter 
                  : position == NotificationPosition.bottom
                      ? Alignment.bottomCenter
                      : Alignment.center,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2), // Starts at 80% scale and grows to 100%
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    if (_activeNotifications.isNotEmpty) {
                      final notification = _activeNotifications.last;
                      notification.remove();
                      _activeNotifications.remove(notification);
                    }
                    if (onTap != null) {
                      onTap();
                    }
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? size.width * 0.95 : size.width * 0.9,
                      minWidth: compact ? size.width * 0.8 : size.width * 0.7,
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(compact ? 12 : 16),
                        boxShadow: [
                          BoxShadow(
                            color: isError
                                ? Colors.red.withOpacity(0.3)
                                : theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(compact ? 12 : 16),
                        child: Stack(
                          children: [
                            // Shimmer effect background
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.1,
                                child: _buildShimmerEffect(),
                              ),
                            ),
                            // Content
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNotificationContent(
                                  context, 
                                  title,
                                  message,
                                  icon,
                                  compact,
                                ),
                                // Optional action button
                                if (actionLabel != null) 
                                  _buildActionButton(
                                    actionLabel,
                                    onActionPressed,
                                  ),
                                // Progress indicator
                                _buildProgressIndicator(duration),
                              ],
                            ),
                          ],
                        ),
                      ),
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
  
  /// Creates the content part of the notification
  static Widget _buildNotificationContent(
    BuildContext context,
    String? title,
    String message,
    IconData icon,
    bool compact,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14.0 : 18.0,
        vertical: compact ? 10.0 : 14.0,
      ),
      child: Row(
        children: [
          // Icon with background
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: compact ? 16 : 18,
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          // Message content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: compact
                        ? (title != null ? 12 : 13)
                        : (title != null ? 13 : 14),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: Icon(
              Icons.close,
              color: Colors.white.withOpacity(0.8),
              size: compact ? 16 : 18,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(Size(compact ? 24 : 32, compact ? 24 : 32)),
            onPressed: () {
              if (_activeNotifications.isNotEmpty) {
                final notification = _activeNotifications.last;
                notification.remove();
                _activeNotifications.remove(notification);
              }
            },
          ),
        ],
      ),
    );
  }
  
  /// Creates the action button for the notification
  static Widget _buildActionButton(
    String actionLabel,
    VoidCallback? onActionPressed,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_activeNotifications.isNotEmpty) {
              final notification = _activeNotifications.last;
              notification.remove();
              _activeNotifications.remove(notification);
            }
            if (onActionPressed != null) {
              onActionPressed();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                actionLabel.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Creates a progress indicator for the notification
  static Widget _buildProgressIndicator(Duration duration) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withOpacity(0.2),
          ),
          minHeight: 2,
        );
      },
    );
  }
  
  /// Creates a shimmer effect for the notification background
  static Widget _buildShimmerEffect() {
    return CustomPaint(
      painter: _ShimmerPainter(),
      size: const Size(double.infinity, double.infinity),
    );
  }
}

/// Custom painter for creating a subtle shimmer pattern
class _ShimmerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Create diagonal stripes for a subtle effect
    for (double i = -size.width; i < size.width * 2; i += 20) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + size.height, size.height)
        ..lineTo(i + size.height - 10, size.height)
        ..lineTo(i - 10, 0)
        ..close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) => false;
}
