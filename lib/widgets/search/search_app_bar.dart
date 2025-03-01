import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../screens/search_screen.dart';
import '../../services/tcg_api_service.dart';
import '../../constants/app_colors.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function() onClearSearch;
  final String currentSort;
  final bool sortAscending;
  final Function() onSortOptionsPressed;
  final bool hasResults;
  final SearchMode searchMode;
  final Function(Set<SearchMode>) onSearchModeChanged;
  final Function() onCameraPressed;

  const SearchAppBar({
    Key? key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.currentSort,
    required this.sortAscending,
    required this.onSortOptionsPressed,
    required this.onCameraPressed,
    this.hasResults = false,
    required this.searchMode,
    required this.onSearchModeChanged,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(hasResults ? 70 : 120);

  IconData _getSortIcon(String sortKey) {
    switch (sortKey) {
      case 'cardmarket.prices.averageSellPrice':
        return sortAscending ? Icons.trending_up : Icons.trending_down;
      case 'name':
        return sortAscending ? Icons.sort_by_alpha : Icons.sort_by_alpha;
      case 'number':
        return sortAscending ? Icons.format_list_numbered : Icons.format_list_numbered_rtl;
      case 'releaseDate':
        return sortAscending ? Icons.calendar_today : Icons.calendar_month;
      default:
        return Icons.sort;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.getSearchHeaderGradient(isDark),
        ),
        boxShadow: isDark ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ] : AppColors.getCardShadow(elevation: 0.7),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar with search field and sort button
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    _buildLeadingButton(context),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSearchField(context)),
                    const SizedBox(width: 8),
                    _buildSortButton(context),
                    // Debug icon removed
                  ],
                ),
              ),
            ),
            
            // Game selector tabs - Only show when not showing results
            if (!hasResults)
              _buildGameSelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [
                  AppColors.darkCardBackground,
                  AppColors.darkBackground,
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: isDark ? 1 : 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildGameOption(context, SearchMode.eng, 'Pokemon', 'assets/icons/pokemon_logo.png'),
          _buildGameOption(context, SearchMode.jpn, 'Japanese', 'assets/icons/jp_flag.png'),
          _buildGameOption(context, SearchMode.mtg, 'Magic', 'assets/icons/mtg_logo.png'),
        ],
      ),
    );
  }

  Widget _buildGameOption(BuildContext context, SearchMode mode, String label, String iconPath) {
    final isSelected = searchMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Enhanced styling for dark mode
    return Expanded(
      child: GestureDetector(
        onTap: () => onSearchModeChanged({mode}),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark 
                    ? AppColors.darkAccentPrimary.withOpacity(0.15)  // More subtle highlight for dark mode
                    : colorScheme.primary.withOpacity(0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isDark 
                      ? AppColors.darkAccentPrimary.withOpacity(0.8)  // Softer accent color for dark mode
                      : colorScheme.primary)
                  : (isDark 
                      ? Colors.white.withOpacity(0.1)  // Very subtle border for dark mode
                      : Colors.black.withOpacity(0.1)),
              width: isSelected ? 1.0 : 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getGameIcon(mode, isDark, isSelected, colorScheme),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark 
                      ? (isSelected 
                          ? AppColors.darkAccentPrimary  // Accent color for selected
                          : Colors.white.withOpacity(0.7))  // Dimmed white for unselected
                      : (isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.8)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _getGameIcon(SearchMode mode, bool isDark, bool isSelected, ColorScheme colorScheme) {
    final color = isDark 
        ? (isSelected ? AppColors.darkAccentPrimary : Colors.white.withOpacity(0.7))
        : (isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.8));
    
    switch (mode) {
      case SearchMode.eng:
        return Icon(Icons.catching_pokemon, size: 18, color: color);
      case SearchMode.jpn:
        return const Text('🇯🇵', style: TextStyle(fontSize: 14));
      case SearchMode.mtg:
        return Icon(Icons.auto_awesome, size: 18, color: color);
    }
  }

  Widget _buildLeadingButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: hasResults 
            ? (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1))
            : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (hasResults) {
              onClearSearch();
            } else {
              onCameraPressed();  // Use the callback instead of direct navigation
            }
          },
          child: Icon(
            hasResults ? Icons.arrow_back_ios_rounded : Icons.camera_alt_rounded,
            size: 22,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? AppColors.searchBarDark : AppColors.searchBarLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark 
                ? Colors.white.withOpacity(0.7)
                : AppColors.searchIconLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: _getPlaceholderText(),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintStyle: TextStyle(
                  color: isDark 
                      ? Colors.white.withOpacity(0.5)
                      : AppColors.searchHintLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                // Remove filled property AND fillColor to prevent the overlay box
                filled: false,
                fillColor: Colors.transparent,
              ),
              style: TextStyle(
                fontSize: 16,
                color: isDark 
                    ? Colors.white 
                    : AppColors.textDark,
              ),
              cursorColor: isDark ? AppColors.darkAccentPrimary : Theme.of(context).primaryColor,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: onSearchChanged,
            ),
          ),
          if (searchController.text.isNotEmpty || hasResults)
            IconButton(
              icon: Icon(
                Icons.clear,
                size: 20,
                color: isDark 
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey[600],
              ),
              onPressed: onClearSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
        ],
      ),
    );
  }
  
  String _getPlaceholderText() {
    switch (searchMode) {
      case SearchMode.eng:
        return 'Search Pokémon cards...';
      case SearchMode.jpn:
        return 'Search Japanese sets...';
      case SearchMode.mtg:
        return 'Search Magic cards...';
    }
  }

  Widget _buildSortButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSortOptionsPressed,
          child: Icon(
            _getSortIcon(currentSort),
            size: 22,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
