import 'package:flutter/material.dart';

class BottomNotification {
  /// Shows a notification from the bottom of the screen
  /// 
  /// You can customize the appearance with title, message, icon, and whether it's an error.
  static void show({
    required BuildContext context,
    required String title,
    String? message,
    IconData? icon,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    final theme = Theme.of(context);
    
    // Create the overlay entry
    final overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: isError
                    ? Colors.red.shade700
                    : theme.colorScheme.primary,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12, 
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (message != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                message,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    
    // Add to overlay and auto-remove after duration
    overlayState.insert(overlayEntry);
    
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}
