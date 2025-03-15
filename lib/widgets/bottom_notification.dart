import 'package:flutter/material.dart';

class BottomNotification extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final bool isError;
  final VoidCallback? onDismiss;

  const BottomNotification({
    Key? key,
    required this.title,
    this.message,
    required this.icon,
    this.isError = false,
    this.onDismiss,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required String title,
    String? message,
    IconData icon = Icons.info_outline,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // Reduced from 80 to 60 to make it closer to the nav bar
        bottom: MediaQuery.of(context).viewInsets.bottom + 60,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: BottomNotification(
              title: title,
              message: message,
              icon: icon,
              isError: isError,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        if (onDismiss != null) {
          onDismiss();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError 
            ? theme.colorScheme.error.withOpacity(0.95)
            : theme.colorScheme.surfaceVariant.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isError
                  ? theme.colorScheme.onError.withOpacity(0.2)
                  : theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isError 
                  ? theme.colorScheme.onError 
                  : theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isError 
                        ? theme.colorScheme.onError 
                        : theme.colorScheme.onSurface,
                    // Remove the decoration entirely to get rid of any underline
                    decoration: TextDecoration.none,
                  ),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isError 
                            ? theme.colorScheme.onError.withOpacity(0.9)
                            : theme.colorScheme.onSurfaceVariant,
                        // Remove the decoration entirely to get rid of any underline
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
