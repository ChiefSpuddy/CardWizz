import 'package:flutter/material.dart';

/// A reusable widget that shows price trend direction with color and icon
class PriceTrendIndicator extends StatelessWidget {
  final double? change;
  final double? percentChange;
  final bool showPercent;
  final bool showIcon;
  final bool compact;
  final TextStyle? textStyle;
  
  const PriceTrendIndicator({
    super.key,
    required this.change,
    this.percentChange,
    this.showPercent = true,
    this.showIcon = true,
    this.compact = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (change == null) return const SizedBox.shrink();
    
    final isUp = change! >= 0;
    final absChange = change!.abs();
    final absPercent = percentChange?.abs() ?? 0;
    
    final color = isUp ? Colors.green.shade600 : Colors.red.shade600;
    final icon = isUp ? Icons.arrow_upward : Icons.arrow_downward;
    
    final baseTextStyle = textStyle ?? 
        Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        );
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon)
          Icon(
            icon,
            color: color,
            size: compact ? 12 : 16,
          ),
        const SizedBox(width: 2),
        Text(
          compact 
            ? '\$${absChange.toStringAsFixed(1)}'
            : (isUp ? '+' : '-') + '\$${absChange.toStringAsFixed(2)}',
          style: baseTextStyle,
        ),
        if (showPercent && percentChange != null) ...[
          const SizedBox(width: 2),
          Text(
            compact 
              ? '(${absPercent.toStringAsFixed(1)}%)'
              : '(${(isUp ? '+' : '-')}${absPercent.toStringAsFixed(1)}%)',
            style: baseTextStyle.copyWith(
              fontSize: baseTextStyle.fontSize! * 0.9,
            ),
          ),
        ],
      ],
    );
  }
}
