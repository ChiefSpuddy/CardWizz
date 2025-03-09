import 'package:flutter/material.dart';

/// Shows a toast notification that appears from the bottom of the screen
/// This is a completely separate implementation from styled_toast.dart
void showBottomToast({
  required BuildContext context,
  required String title, 
  required String message,
  IconData icon = Icons.check_circle,
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
}) {
  OverlayState? overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;
  
  // Calculate the bottom safe area to avoid notches
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  
  overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        // Explicitly positioned at bottom
        bottom: 80 + bottomPadding,
        left: 20,
        right: 20,
        child: _BottomToastWidget(
          title: title,
          message: message,
          icon: icon,
          isError: isError,
          onDismiss: () {
            overlayEntry.remove();
          },
        ),
      );
    },
  );
  
  overlayState.insert(overlayEntry);
  
  // Automatically dismiss after duration
  Future.delayed(duration, () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

class _BottomToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool isError;
  final VoidCallback onDismiss;
  
  const _BottomToastWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    required this.isError,
    required this.onDismiss,
  }) : super(key: key);
  
  @override
  _BottomToastWidgetState createState() => _BottomToastWidgetState();
}

class _BottomToastWidgetState extends State<_BottomToastWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Slide up from bottom animation
    _slideAnimation = Tween<double>(
      begin: 50.0,  // Start 50 pixels below final position
      end: 0.0,     // End at final position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Determine the background color based on the current theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Color(0xFF2D2D2D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              elevation: 6.0,
              borderRadius: BorderRadius.circular(12.0),
              color: backgroundColor,
              child: InkWell(
                onTap: _dismiss,
                borderRadius: BorderRadius.circular(12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10.0),
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
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 20, color: subtitleColor),
                        onPressed: _dismiss,
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
  }
}
