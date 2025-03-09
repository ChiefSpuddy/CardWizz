import 'package:flutter/material.dart';

/// A completely different implementation focused specifically on showing notifications
/// from the bottom of the screen with proper animation and positioning.
class BottomNotification {
  /// Show a notification that appears from the bottom of the screen
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.info_outline,
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Get overlay state
    final overlayState = Overlay.of(context);
    
    // Store entry for later removal
    late OverlayEntry entry;
    
    // Get device safe area
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final screenSize = MediaQuery.of(context).size;
    
    entry = OverlayEntry(
      builder: (context) => _BottomNotificationWidget(
        title: title,
        message: message,
        icon: icon,
        isError: isError,
        bottomInset: bottomInset,
        screenWidth: screenSize.width,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    
    overlayState.insert(entry);
    
    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _BottomNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool isError;
  final double bottomInset;
  final double screenWidth;
  final VoidCallback onDismiss;
  
  const _BottomNotificationWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.isError = false,
    required this.bottomInset,
    required this.screenWidth,
    required this.onDismiss,
  }) : super(key: key);
  
  @override
  _BottomNotificationWidgetState createState() => _BottomNotificationWidgetState();
}

class _BottomNotificationWidgetState extends State<_BottomNotificationWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Create a slide up animation from below the screen
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start from below the screen
      end: Offset.zero,          // End at the target position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    // Create a fade in animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Start the animation
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Use an explicit positioned widget at the bottom of the screen
    return Positioned(
      bottom: 80 + widget.bottomInset,
      // Center horizontally with padding
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2D2D2D)
                : Colors.white,
            child: InkWell(
              onTap: () {
                _controller.reverse().then((_) {
                  widget.onDismiss();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black45,
                      ),
                      onPressed: () {
                        _controller.reverse().then((_) {
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
  }
}
