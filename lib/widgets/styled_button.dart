import 'package:flutter/material.dart';
import '../utils/color_extensions.dart';

class StyledButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final IconData? icon;
  final bool outlined;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final bool compact;
  final bool disabled;
  
  const StyledButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.height = 48,
    this.width,
    this.borderRadius = 8,
    this.icon,
    this.outlined = false,
    this.fullWidth = false,
    this.padding,
    this.compact = false,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;
    final buttonTextColor = textColor ?? (outlined ? buttonColor : Colors.white);
    
    final buttonStyle = outlined
        ? OutlinedButton.styleFrom(
            side: BorderSide(color: buttonColor),
            foregroundColor: buttonTextColor,
            backgroundColor: Colors.transparent,
            padding: padding ?? (compact 
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 0)
                : const EdgeInsets.symmetric(horizontal: 24)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
            elevation: 0,
            padding: padding ?? (compact
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 0)
                : const EdgeInsets.symmetric(horizontal: 24)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          );
    
    final buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: buttonTextColor.withAlpha((0.8 * 255).round()), // Fixed: Using withAlpha
              strokeCap: StrokeCap.round,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
    
    final button = outlined
        ? OutlinedButton(
            onPressed: disabled || isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonChild,
          )
        : ElevatedButton(
            onPressed: disabled || isLoading ? null : onPressed,
            style: buttonStyle,
            child: buttonChild,
          );
    
    return SizedBox(
      width: fullWidth ? double.infinity : width,
      height: height,
      child: button,
    );
  }
}
