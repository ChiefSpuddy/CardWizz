import 'package:flutter/material.dart';

class SortIndicatorBadge extends StatelessWidget {
  final String sortField;
  final bool ascending;
  final VoidCallback onTap;

  const SortIndicatorBadge({
    Key? key,
    required this.sortField,
    required this.ascending,
    required this.onTap,
  }) : super(key: key);

  String get _getSortDisplayName {
    switch (sortField) {
      case 'cardmarket.prices.averageSellPrice':
        // Make price display shorter
        return ascending ? 'Price ↑' : 'Price ↓';
      case 'name':
        // Make name display shorter
        return ascending ? 'A-Z' : 'Z-A';
      case 'number':
        // Make number display shorter
        return ascending ? '#↑' : '#↓';
      default:
        return 'Sort';
    }
  }

  IconData get _getSortIcon {
    switch (sortField) {
      case 'cardmarket.prices.averageSellPrice':
        return ascending ? Icons.arrow_upward : Icons.arrow_downward;
      case 'name':
        return ascending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined;
      case 'number':
        return ascending ? Icons.format_list_numbered : Icons.format_list_numbered_rtl;
      default:
        return Icons.sort;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Make the badge much more compact
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSortIcon,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                _getSortDisplayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
