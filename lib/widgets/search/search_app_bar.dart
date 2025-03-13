import 'package:flutter/material.dart';
import '../../screens/search_screen.dart';
import '../../constants/app_colors.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final String currentSort;
  final bool sortAscending;
  final VoidCallback onSortOptionsPressed;
  final bool hasResults;
  final SearchMode searchMode;
  final Function(List<SearchMode>) onSearchModeChanged;
  final VoidCallback onCameraPressed;

  const SearchAppBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.currentSort,
    required this.sortAscending,
    required this.onSortOptionsPressed,
    required this.hasResults,
    required this.searchMode,
    required this.onSearchModeChanged,
    required this.onCameraPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120); // Increased height for the expanded design

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkCardBackground : colorScheme.surface;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // App bar with back button and title
            Row(
              children: [
                // Menu or back button
                IconButton(
                  icon: Icon(
                    hasResults ? Icons.arrow_back : Icons.menu,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: hasResults ? onClearSearch : () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                
                // Title and optional subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (hasResults)
                        Text(
                          '${searchController.text} (${_getCurrentSortText()})',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Action buttons - separate for better spacing
                IconButton(
                  icon: Icon(
                    Icons.sort,
                    color: colorScheme.primary,
                  ),
                  onPressed: onSortOptionsPressed,
                  tooltip: 'Sort Results',
                ),
                
                IconButton(
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: colorScheme.primary,
                  ),
                  onPressed: onCameraPressed,
                  tooltip: 'Scan Card',
                ),
              ],
            ),
            
            // Beautiful search bar design
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  // Expanded search field with modern design
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? colorScheme.surfaceVariant.withOpacity(0.4)
                            : colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(
                            Icons.search,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: onSearchChanged,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Search for cards...',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (searchController.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: colorScheme.onSurfaceVariant,
                                size: 18,
                              ),
                              onPressed: onClearSearch,
                              visualDensity: VisualDensity.compact,
                              splashRadius: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Separate database selection button with modern design
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildModeSelector(context, colorScheme, isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showModeSelection(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getModeIcon(),
              const SizedBox(width: 4),
              Text(
                _getModeText(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down,
                color: colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModeText() {
    switch (searchMode) {
      case SearchMode.eng:
        return 'PKM';
      case SearchMode.mtg:
        return 'MTG';
      default:
        return 'PKM';
    }
  }

  Widget _getModeIcon() {
    IconData iconData;
    switch (searchMode) {
      case SearchMode.eng:
        iconData = Icons.catching_pokemon;
        break;
      case SearchMode.mtg:
        iconData = Icons.auto_awesome;
        break;
      default:
        iconData = Icons.catching_pokemon;
    }
    
    return Icon(
      iconData,
      size: 16,
      color: Colors.blue.shade700,
    );
  }

  void _showModeSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.search, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Select Database',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.catching_pokemon),
            ),
            title: const Text('Pokémon TCG'),
            subtitle: const Text('Search English Pokémon cards'),
            selected: searchMode == SearchMode.eng,
            trailing: searchMode == SearchMode.eng ? 
              Icon(Icons.check_circle, color: colorScheme.primary) : null,
            onTap: () {
              Navigator.pop(context);
              onSearchModeChanged([SearchMode.eng]);
            },
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome),
            ),
            title: const Text('Magic: The Gathering'),
            subtitle: const Text('Search MTG cards'),
            selected: searchMode == SearchMode.mtg,
            trailing: searchMode == SearchMode.mtg ? 
              Icon(Icons.check_circle, color: colorScheme.primary) : null,
            onTap: () {
              Navigator.pop(context);
              onSearchModeChanged([SearchMode.mtg]);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getCurrentSortText() {
    String sortText = '';
    
    if (currentSort == 'cardmarket.prices.averageSellPrice') {
      sortText = sortAscending ? 'Price ▲' : 'Price ▼';
    } else if (currentSort == 'name') {
      sortText = sortAscending ? 'Name A-Z' : 'Name Z-A';
    } else if (currentSort == 'number') {
      sortText = sortAscending ? 'Number ▲' : 'Number ▼';
    } else {
      sortText = 'Sorted';
    }

    return sortText;
  }
}
