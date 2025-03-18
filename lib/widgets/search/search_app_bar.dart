import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/search_screen.dart';
import '../../constants/app_colors.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onSortOptionsPressed;
  final String currentSort;
  final bool sortAscending;
  final bool hasResults;
  final SearchMode searchMode;
  final Function(List<SearchMode>) onSearchModeChanged;
  final VoidCallback onCameraPressed;
  final VoidCallback onCancelSearch; // Add this new callback

  const SearchAppBar({
    Key? key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortOptionsPressed,
    required this.currentSort,
    required this.sortAscending,
    required this.hasResults,
    required this.searchMode,
    required this.onSearchModeChanged,
    required this.onCameraPressed,
    required this.onCancelSearch, // Add this required parameter
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  // Add a focus node to manage keyboard focus directly
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false; // Add a state to track if we're actively searching
  
  @override
  void initState() {
    super.initState();
    // Add a tiny delay before adding the listener to avoid initial state issues
    Future.microtask(() {
      _searchFocusNode.addListener(_onFocusChange);
    });

    // Initialize with current search state
    _isSearching = widget.searchController.text.isNotEmpty;

    // Add listener to track when search begins
    widget.searchController.addListener(_onSearchControllerChange);
  }

  void _onSearchControllerChange() {
    final isTextEmpty = widget.searchController.text.isEmpty;
    if (_isSearching != !isTextEmpty) {
      setState(() {
        _isSearching = !isTextEmpty;
      });
    }
  }
  
  void _onFocusChange() {
    // When focused, ensure keyboard shows immediately by sending a platform channel message
    if (_searchFocusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    widget.searchController.removeListener(_onSearchControllerChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      titleSpacing: 0,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : Colors.black87,
      ),
      title: Container(
        height: kToolbarHeight - 16,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search,
              color: isDark ? Colors.white70 : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            // Use RawKeyboardListener to optimize keyboard performance
            Expanded(
              child: RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  // Handle keyboard events if needed
                },
                child: TextField(
                  controller: widget.searchController,
                  focusNode: _searchFocusNode,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search cards...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[500],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  textInputAction: TextInputAction.search,
                  // Add this critical property to ensure immediate keyboard appearance
                  keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
                ),
              ),
            ),
            if (widget.searchController.text.isNotEmpty)
              // Enhanced cancel button - more visible and handles both clear and cancel
              GestureDetector(
                onTap: () {
                  widget.onClearSearch(); // Clear the text
                  widget.onCancelSearch(); // Cancel search and return to categories
                  _searchFocusNode.requestFocus(); // Keep focus after clearing
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? colorScheme.primary.withOpacity(0.2) 
                        : colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : colorScheme.primary,
                    size: 18,
                  ),
                ),
              ),
            // Camera button with enhanced styling
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: widget.onCameraPressed,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: isDark ? colorScheme.primary.withOpacity(0.9) : colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.hasResults && _isSearching)
          IconButton(
            icon: Icon(
              Icons.sort,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
            onPressed: widget.onSortOptionsPressed,
            tooltip: 'Sort',
          ),
        _buildSearchModeToggle(isDark, colorScheme),
      ],
    );
  }

  Widget _buildSearchModeToggle(bool isDark, ColorScheme colorScheme) {
    final searchMode = widget.searchMode;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<SearchMode>(
        initialValue: searchMode,
        icon: Icon(
          searchMode == SearchMode.eng ? Icons.catching_pokemon : Icons.auto_awesome,
          size: 24,
          color: searchMode == SearchMode.eng 
              ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
              : (isDark ? Colors.blue.shade300 : Colors.blue.shade700),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: (mode) {
          widget.onSearchModeChanged([mode]);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: SearchMode.eng,
            child: Row(
              children: [
                Icon(
                  Icons.catching_pokemon, 
                  size: 20,
                  color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                ),
                const SizedBox(width: 12),
                const Text('Pokémon'),
              ],
            ),
          ),
          PopupMenuItem(
            value: SearchMode.mtg,
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome, 
                  size: 20,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                const Text('Magic: The Gathering'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
