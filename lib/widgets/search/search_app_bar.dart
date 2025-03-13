import 'package:flutter/material.dart';
import '../../screens/search_screen.dart';

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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Container(
        height: 40,
        // IMPROVED LAYOUT: Use a Row with better spacing
        child: Row(
          children: [
            // Dropdown now has a fixed width
            Container(
              width: 72, // Fixed width for dropdown
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildModeDropdown(context),
            ),
            // Expanded search field takes remaining space
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search..',
                    isDense: true, // More compact height
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              onClearSearch();
                            },
                          )
                        : null,
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (hasResults)
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: onSortOptionsPressed,
          ),
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: onCameraPressed,
        ),
      ],
    );
  }

  Widget _buildModeDropdown(BuildContext context) {
    final items = [SearchMode.eng, SearchMode.mtg];
    final labels = {'eng': 'PKM', 'mtg': 'MTG'};
    
    return DropdownButton<SearchMode>(
      value: searchMode,
      underline: Container(), // No underline
      icon: const Icon(Icons.arrow_drop_down, size: 20),
      iconSize: 20, // Smaller icon
      isDense: true, // Reduces the overall button size
      padding: EdgeInsets.zero, // No extra padding
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
      items: items.map((mode) {
        return DropdownMenuItem<SearchMode>(
          value: mode,
          child: Text(
            labels[mode.toString().split('.').last.toLowerCase()] ?? 'PKM',
            style: TextStyle(
              fontSize: 13, // Smaller text size
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onSearchModeChanged([value]);
        }
      },
    );
  }
}
