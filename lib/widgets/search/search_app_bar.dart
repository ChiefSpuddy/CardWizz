import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../screens/search_screen.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSortOptionsPressed;
  final String currentSort;
  final bool sortAscending;
  final bool hasResults;
  final Function(List<SearchMode>) onSearchModeChanged;
  final SearchMode searchMode;
  final VoidCallback onCameraPressed;

  const SearchAppBar({
    Key? key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortOptionsPressed,
    required this.currentSort,
    required this.sortAscending,
    required this.hasResults,
    required this.onSearchModeChanged,
    required this.searchMode,
    required this.onCameraPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight - 12); // Even more compact

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Ensure app bar is truly transparent
    final backgroundColor = Colors.transparent;

    // Get text field styling
    final searchBarColor = isDark 
        ? AppColors.searchBarDark.withOpacity(0.7)
        : AppColors.searchBarLight;
        
    final textColor = isDark
        ? Colors.white.withOpacity(0.95)
        : Colors.black87;

    final hintColor = isDark
        ? Colors.white.withOpacity(0.6)
        : Colors.black54;

    // Configure status bar - transparent with icons matching theme
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );

    // Use pre-rendering widget for transparency management
    return PreferredSize(
      preferredSize: preferredSize,
      child: ClipRect(
        child: BackdropFilter(
          filter: const ColorFilter.matrix([
            1, 0, 0, 0, 0,
            0, 1, 0, 0, 0,
            0, 0, 1, 0, 0,
            0, 0, 0, 1, 0,
          ]), // Identity matrix for true transparency
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                children: [
                  // Menu button - more compact
                  IconButton(
                    icon: const Icon(Icons.menu, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                  
                  // IMPROVED: Search mode selector - MORE VISIBLY A MENU
                  _buildImprovedSearchModeToggle(context, colorScheme, isDark),
                  
                  // Search field
                  Expanded(
                    child: Container(
                      height: 38, // Reduced height
                      decoration: BoxDecoration(
                        color: searchBarColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          width: 0.5,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        style: TextStyle(
                          fontSize: 14, // SMALLER font for better fit
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: _getSearchPlaceholder(searchMode),
                          hintStyle: TextStyle(
                            fontSize: 14, // SMALLER font for better fit
                            color: hintColor,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10
                          ),
                          border: InputBorder.none,
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    searchController.clear();
                                    onClearSearch();
                                  },
                                )
                              : null,
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18, // SMALLER icon for consistent sizing
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 4),
                  
                  // Action buttons
                  _buildIconButton(
                    icon: _getSortIcon(currentSort, sortAscending),
                    onPressed: onSortOptionsPressed,
                    visible: hasResults,
                  ),
                  
                  _buildIconButton(
                    icon: Icons.qr_code_scanner,
                    onPressed: onCameraPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Improved search mode toggle with dropdown indicator
  Widget _buildImprovedSearchModeToggle(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showModeSelectionDialog(context);
        },
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.primary.withOpacity(0.15)
                  : colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getModeIcon(searchMode),
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _getModeShortName(searchMode),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                // NEW: Dropdown indicator
                Icon(
                  Icons.arrow_drop_down,
                  size: 14,
                  color: colorScheme.primary,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show full-screen mode selection dialog for better visibility
  void _showModeSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Search Mode'),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pokémon option
            _buildModeDialogOption(
              context: context,
              mode: SearchMode.eng,
              title: 'Pokémon Cards',
              subtitle: 'Search for English Pokémon cards',
              icon: Icons.catching_pokemon,
            ),
            
            // MTG option
            _buildModeDialogOption(
              context: context,
              mode: SearchMode.mtg,
              title: 'Magic: The Gathering',
              subtitle: 'Search for MTG cards',
              icon: Icons.auto_awesome,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  // Build a dialog option with more information
  Widget _buildModeDialogOption({
    required BuildContext context,
    required SearchMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = searchMode == mode;
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () {
        onSearchModeChanged([mode]);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // More compact icon button
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool visible = true,
  }) {
    if (!visible) return const SizedBox(width: 4);
    
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        icon: Icon(icon, size: 20),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
      ),
    );
  }
  
  // Get short mode name for display
  String _getModeShortName(SearchMode mode) {
    switch (mode) {
      case SearchMode.eng:
        return 'Pokémon';
      case SearchMode.mtg:
        return 'MTG';
    }
  }
  
  // Get mode icon
  IconData _getModeIcon(SearchMode mode) {
    switch (mode) {
      case SearchMode.eng:
        return Icons.catching_pokemon;
      case SearchMode.mtg:
        return Icons.auto_awesome;
    }
  }
  
  // UPDATED: Get more concise search placeholder text
  String _getSearchPlaceholder(SearchMode mode) {
    switch (mode) {
      case SearchMode.eng:
        return 'Search Pokémon...'; // Shortened text
      case SearchMode.mtg:
        return 'Search Magic cards...';
    }
  }
  
  // Get sort icon
  IconData _getSortIcon(String sort, bool ascending) {
    switch (sort) {
      case 'cardmarket.prices.averageSellPrice':
        return ascending ? Icons.trending_up : Icons.trending_down;
      case 'name':
        return ascending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined;
      case 'number':
        return ascending ? Icons.format_list_numbered : Icons.format_list_numbered_rtl;
      default:
        return Icons.sort;
    }
  }
}
