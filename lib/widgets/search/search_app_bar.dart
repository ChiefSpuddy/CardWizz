import 'package:flutter/material.dart';
import '../../screens/search_screen.dart';
import '../../services/tcg_api_service.dart';
import '../../l10n/app_localizations.dart';

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
  Size get preferredSize => const Size.fromHeight(96); // Adjust height as needed

  IconData _getSortIcon(String sortKey) {
    switch (sortKey) {
      case 'price:desc':
      case 'price:asc':
        return Icons.attach_money;
      case 'name:asc':
      case 'name:desc':
        return Icons.sort_by_alpha;
      case 'releaseDate:desc':
      case 'releaseDate:asc':
        return Icons.calendar_today;
      default:
        return Icons.sort;
    }
  }

  // Helper for segment labels
  Widget _buildSegmentLabel(BuildContext context, String emoji, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: double.infinity,
      width: MediaQuery.of(context).size.width * 0.28, // Adjusted width for 3 segments
      decoration: BoxDecoration(
        gradient: searchMode.toString() == 'SearchMode.${text.toLowerCase()}' 
          ? LinearGradient(
              colors: isDark ? [
                Colors.blue[900]!,
                Colors.blue[800]!,
              ] : [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ) 
          : null,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: searchMode.toString() == 'SearchMode.${text.toLowerCase()}'
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 44,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leadingWidth: 72,
      leading: hasResults
          ? // Show back button when viewing results
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onClearSearch,
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                    ),
                  ),
                ),
              ),
            )
          : // Show camera button on main search view
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onClearSearch,
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: searchMode == SearchMode.eng 
                    ? 'Search cards...' 
                    : 'Search sets...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: onSearchChanged,
              ),
            ),
            if (searchController.text.isNotEmpty || hasResults)
              IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: onClearSearch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _getSortIcon(currentSort),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: TcgApiService.sortOptions[currentSort],
          onPressed: onSortOptionsPressed,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SegmentedButton<SearchMode>(
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                side: MaterialStateProperty.all(BorderSide.none),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              selected: {searchMode},
              onSelectionChanged: onSearchModeChanged,
              segments: [
                // Existing ENG segment
                ButtonSegment(
                  value: SearchMode.eng,
                  label: _buildSegmentLabel(context, '🇺🇸', 'ENG'),
                ),
                // Existing JPN segment
                ButtonSegment(
                  value: SearchMode.jpn,
                  label: _buildSegmentLabel(context, '🇯🇵', 'JPN'),
                ),
                // New MTG segment
                ButtonSegment(
                  value: SearchMode.mtg,
                  label: _buildSegmentLabel(context, '✨', 'MTG'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
