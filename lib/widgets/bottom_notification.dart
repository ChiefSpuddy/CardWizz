import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

class BottomNotification {
  static OverlayEntry? _currentNotification;
  static Timer? _dismissTimer;

  static void show({
    required BuildContext context,
    required String title,
    String? message,
    IconData? icon,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    try {
      hide();
      
      final overlay = Overlay.of(context);
      if (overlay == null) return;
      
      final navigator = Navigator.of(context);
      if (!navigator.mounted) return;
      
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      _currentNotification = OverlayEntry(
        builder: (overlayContext) {
          final mediaQuery = MediaQuery.of(overlayContext);
          final bottomPadding = mediaQuery.padding.bottom;
          final bottomInset = mediaQuery.viewInsets.bottom;
          final screenWidth = mediaQuery.size.width;
          
          return Positioned(
            bottom: bottomPadding + 8 + (bottomInset > 0 ? bottomInset : 0),
            width: screenWidth,
            child: Center(
              child: IgnorePointer(
                child: Container(
                  width: screenWidth * 0.9,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isError
                          ? [Colors.red.shade800, Colors.red.shade900]
                          : isDarkMode
                              ? [Colors.grey.shade900, Colors.black]
                              : [Colors.grey.shade900, Colors.grey.shade800],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: isError
                          ? Colors.red.shade700.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  // REMOVED BackdropFilter that was causing yellow underlines
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isError
                                  ? Colors.red.shade600.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (message != null && message.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: const TextStyle(
                                    color: Colors.white70,
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (overlay.mounted) {
          overlay.insert(_currentNotification!);
        }
      });

      _dismissTimer = Timer(duration, () {
        hide();
      });
    } catch (e) {
      debugPrint('Error showing bottom notification: $e');
    }
  }

  static void hide() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    
    try {
      _currentNotification?.remove();
    } catch (e) {
      debugPrint('Error hiding notification: $e');
    } finally {
      _currentNotification = null;
    }
  }
}
