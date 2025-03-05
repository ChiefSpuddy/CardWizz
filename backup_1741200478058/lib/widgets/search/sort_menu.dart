import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SortMenu extends StatelessWidget {
  final String currentSort;
  final bool sortAscending;
  final Function(String, bool) onSortChanged;

  const SortMenu({
    Key? key,
    required this.currentSort,
    required this.sortAscending,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle grip
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header with title and close button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort Cards By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Sort options
          _buildSortOption(
            context, 
            title: 'Price (High to Low)',
            sortKey: 'cardmarket.prices.averageSellPrice',
            isAscending: false,
            icon: Icons.trending_down,
          ),
          _buildSortOption(
            context,
            title: 'Price (Low to High)',
            sortKey: 'cardmarket.prices.averageSellPrice',
            isAscending: true,
            icon: Icons.trending_up,
          ),
          
          const Divider(height: 16, indent: 16, endIndent: 16),
          
          // Name sorting
          _buildSortOption(
            context,
            title: 'Name (A to Z)',
            sortKey: 'name',
            isAscending: true,
            icon: Icons.sort_by_alpha,
          ),
          _buildSortOption(
            context,
            title: 'Name (Z to A)',
            sortKey: 'name',
            isAscending: false,
            icon: Icons.sort_by_alpha,
          ),
          
          const Divider(height: 16, indent: 16, endIndent: 16),
          
          // Number sorting
          _buildSortOption(
            context,
            title: 'Number (Low to High)',
            sortKey: 'number',
            isAscending: true,
            icon: Icons.format_list_numbered,
          ),
          _buildSortOption(
            context,
            title: 'Number (High to Low)',
            sortKey: 'number',
            isAscending: false,
            icon: Icons.format_list_numbered_rtl,
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required String title,
    required String sortKey,
    required bool isAscending,
    required IconData icon,
  }) {
    final isSelected = currentSort == sortKey && sortAscending == isAscending;
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () {
        onSortChanged(sortKey, isAscending);
        Navigator.pop(context);
        HapticFeedback.lightImpact();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}