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
  final VoidCallback? onActionPressed; // Add this parameter for backward compatibility

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
    this.onActionPressed, // Add this parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final txtColor = textColor ?? Colors.white;
    final icnColor = iconColor ?? txtColor;

    // Use either onAction or onActionPressed callback (prefer onAction if both are provided)
    final actionCallback = onAction ?? onActionPressed;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (icon != null)  
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: icnColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: icnColor,
                      size: 24,
                    ),
                  ),
                if (icon != null)  
                  const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: txtColor,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: txtColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (actionLabel != null && actionCallback != null) 
                  TextButton(
                    onPressed: actionCallback,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        color: txtColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else  
                  Icon(
                    Icons.chevron_right,
                    color: txtColor.withOpacity(0.7),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
