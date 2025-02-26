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

  const SearchAppBar({
    Key? key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.currentSort,
    required this.sortAscending,
    required this.onSortOptionsPressed,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.getGradientForGameType(searchMode.toString().split('.').last),
        ),
        boxShadow: AppColors.getCardShadow(elevation: 0.7),
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

  List<Color> _getAppBarGradient(BuildContext context, SearchMode mode, bool isDark) {
    if (isDark) {
      // Dark mode gradients
      switch (mode) {
        case SearchMode.eng:
          return [
            const Color(0xFF1A237E), // Deep Pokémon blue
            const Color(0xFF303F9F),
          ];
        case SearchMode.jpn:
          return [
            const Color(0xFF7F0000), // Deep Japanese red
            const Color(0xFFC62828),
          ];
        case SearchMode.mtg:
          return [
            const Color(0xFF3E2723), // Deep MTG brown
            const Color(0xFF5D4037),
          ];
      }
    } else {
      // Light mode gradients
      switch (mode) {
        case SearchMode.eng:
          return [
            const Color(0xFF3F51B5), // Pokémon blue
            const Color(0xFF5C6BC0),
          ];
        case SearchMode.jpn:
          return [
            const Color(0xFFD32F2F), // Japanese red
            const Color(0xFFE57373),
          ];
        case SearchMode.mtg:
          return [
            const Color(0xFF795548), // MTG brown
            const Color(0xFF8D6E63),
          ];
      }
    }
  }

  Widget _buildLeadingButton(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: hasResults 
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.1),
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
              _showCameraScanToast(context);
            }
          },
          child: Icon(
            hasResults ? Icons.arrow_back_ios_rounded : Icons.camera_alt_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  void _showCameraScanToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 16),
            const SizedBox(width: 12),
            const Text('Card scanning coming soon!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 120,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDark ? 0.12 : 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: _getPlaceholderText(),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: onSearchChanged,
            ),
          ),
          if (searchController.text.isNotEmpty || hasResults)
            IconButton(
              icon: const Icon(
                Icons.clear,
                size: 20,
                color: Colors.white,
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
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
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
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGameSelector(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onSearchModeChanged({mode}),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use appropriate icon for each game
              _getGameIcon(mode),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
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
  
  Widget _getGameIcon(SearchMode mode) {
    switch (mode) {
      case SearchMode.eng:
        return const Icon(Icons.catching_pokemon, size: 18, color: Colors.white);
      case SearchMode.jpn:
        return const Text('🇯🇵', style: TextStyle(fontSize: 14));
      case SearchMode.mtg:
        return const Icon(Icons.auto_awesome, size: 18, color: Colors.white);
    }
  }
}
