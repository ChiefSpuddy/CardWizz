import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class SearchCategoriesHeader extends StatelessWidget {
  final bool showCategories;
  final VoidCallback onToggleCategories;

  const SearchCategoriesHeader({
    Key? key,
    required this.showCategories,
    required this.onToggleCategories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withAlpha((0.1 * 255).round()),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha((0.05 * 255).round()),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              // Add subtle background gradient when expanded
              gradient: showCategories 
                ? isDark 
                  ? AppColors.getDarkModeGradient(0.5) 
                  : AppColors.getLightModeGradient(0.5)
                : null,
              color: showCategories 
                ? Colors.transparent
                : isDark 
                  ? AppColors.darkCardBackground.withOpacity(0.7)
                  : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleCategories,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        // Icon with pulsating gradient container
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: showCategories
                              ? LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                    colorScheme.tertiary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                            color: showCategories 
                              ? null
                              : colorScheme.surfaceVariant.withOpacity(0.4),
                            boxShadow: showCategories ? [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ] : null,
                          ),
                          child: Icon(
                            showCategories ? Icons.category : Icons.search,
                            size: 16,
                            color: showCategories
                              ? Colors.white
                              : colorScheme.primary,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Search Categories',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  showCategories 
                                    ? 'Tap a category to search' 
                                    : 'Browse all sets by era or type',
                                  key: ValueKey(showCategories),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Animated chevron
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: showCategories ? 0.0 : 0.5,
                            end: showCategories ? 0.5 : 0.0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 3.14159,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: showCategories
                                    ? colorScheme.primary.withOpacity(0.15)
                                    : colorScheme.surfaceVariant.withOpacity(0.3),
                                ),
                                child: Icon(
                                  Icons.expand_more,
                                  color: showCategories
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Animated divider visibility
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: showCategories ? 12 : 1,
            child: showCategories 
              ? const SizedBox() 
              : Divider(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  thickness: 1,
                ),
          ),
        ],
      ),
    );
  }
}
