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

/// A helper function to show a styled toast notification
void showToast({
  required BuildContext context,
  required String title,
  String subtitle = '',
  IconData? icon,
  Color? backgroundColor,
  bool isError = false,
  bool compact = false,
  int durationSeconds = 2,
  VoidCallback? onTap,
}) {
  // Use error color if isError is true
  final bgColor = isError
      ? Theme.of(context).colorScheme.error
      : backgroundColor ?? Theme.of(context).colorScheme.primary;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => Padding(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StyledToast(
            title: title,
            subtitle: subtitle,
            icon: icon,
            backgroundColor: bgColor,
            onTap: onTap ?? () => Navigator.of(context).pop(),
            compact: compact,
          ),
        ],
      ),
    ),
  );

  // Auto-dismiss after the duration
  Future.delayed(Duration(seconds: durationSeconds), () {
    if (context.mounted) {
      Navigator.of(context).popUntil((route) {
        return route is! ModalBottomSheetRoute;
      });
    }
  });
}
