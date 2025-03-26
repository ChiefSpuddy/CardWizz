import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/search_screen.dart'; // For SearchMode enum
import '../../constants/app_colors.dart';
import '../../services/logging_service.dart'; 

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSortOptionsPressed;
  final bool hasResults;
  final String currentSort;
  final bool sortAscending;
  final SearchMode searchMode;
  // Fix the type: Change from List<SearchMode> to Set<SearchMode>
  final Function(Set<SearchMode>) onSearchModeChanged;
  final VoidCallback onCameraPressed;
  final VoidCallback onCancelSearch;
  final Function(String) onSubmitted;

  const SearchAppBar({
    Key? key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortOptionsPressed,
    required this.hasResults,
    required this.currentSort, 
    required this.sortAscending,
    required this.searchMode,
    required this.onSearchModeChanged,
    required this.onCameraPressed,
    required this.onCancelSearch,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _SearchAppBarState extends State<SearchAppBar> {
  late FocusNode _focusNode;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isSearchFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return AppBar(
      title: Row(
        children: [
          // Make toggle much more compact
          Container(
            height: 32, // Reduced height
            constraints: const BoxConstraints(maxWidth: 65), // Constrain width
            child: SegmentedButton<SearchMode>(
              showSelectedIcon: false,
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                // Extreme compactness with minimal padding
                padding: MaterialStateProperty.all(
                  EdgeInsets.zero, // Remove all padding
                ),
                // Reduce icon size
                iconSize: MaterialStateProperty.all(10),
                // Minimal shape with smaller border radius
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Smaller overall button
                minimumSize: MaterialStateProperty.all(
                  const Size(28, 26),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: SearchMode.eng,
                  label: Text('PKM', style: TextStyle(fontSize: 10)), // Smaller text
                ),
                ButtonSegment(
                  value: SearchMode.mtg,
                  label: Text('MTG', style: TextStyle(fontSize: 10)), // Smaller text
                ),
              ],
              selected: {widget.searchMode},
              onSelectionChanged: widget.onSearchModeChanged,
            ),
          ),
          
          const SizedBox(width: 6), // Reduce spacing
          
          // Search field with expanded width
          Expanded(
            child: Container(
              height: 38, // Reduced height slightly
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSearchFocused
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6), // Reduced
                  const Icon(Icons.search, size: 16), // Smaller icon
                  const SizedBox(width: 6), // Reduced
                  Expanded(
                    child: TextField(
                      controller: widget.searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Search cards...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white54
                              : Colors.black38,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onChanged: widget.onSearchChanged,
                      onSubmitted: widget.onSubmitted,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (widget.searchController.text.isNotEmpty)
                    SizedBox(
                      width: 28, // Fixed width for clear button
                      height: 28, // Fixed height
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16), // Smaller icon
                        onPressed: widget.onClearSearch,
                        splashRadius: 16, // Smaller splash
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Sort button - only shown when results are visible
        if (widget.hasResults)
          IconButton(
            icon: Icon(
              widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward, 
              size: 20,
            ),
            onPressed: widget.onSortOptionsPressed,
            tooltip: 'Sort options',
            padding: const EdgeInsets.all(8), // Add more compact padding
          ),
        
        // Camera button
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined, size: 20),
          onPressed: widget.onCameraPressed,
          tooltip: 'Scan card',
          padding: const EdgeInsets.all(8), // Add more compact padding
        ),
      ],
      elevation: 0,
    );
  }
}
