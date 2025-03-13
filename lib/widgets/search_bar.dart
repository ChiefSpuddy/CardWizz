import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../screens/search_screen.dart';

class SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onSearch;
  final VoidCallback onClear;
  final SearchMode searchMode;
  final Function(SearchMode) onSearchModeChanged;
  
  // New parameters for customization
  final Color backgroundColor;
  final Color textColor;
  final Color hintColor;
  final Color iconColor;

  const SearchBar({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.onSearch,
    required this.onClear,
    required this.searchMode,
    required this.onSearchModeChanged,
    required this.backgroundColor,
    required this.textColor,
    required this.hintColor,
    required this.iconColor,
  }) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _isFocused) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search,
            color: widget.iconColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                hintStyle: TextStyle(color: widget.hintColor),
              ),
              style: TextStyle(color: widget.textColor),
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSearch,
            ),
          ),
          _buildSearchModeSelector(),
          if (widget.controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: widget.iconColor),
              onPressed: () {
                widget.onClear();
                widget.controller.clear();
              },
              splashRadius: 20,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSearchModeSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showSearchModeMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.primaryContainer.withOpacity(0.4)
                : colorScheme.primaryContainer.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getModeText(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark 
                      ? colorScheme.onPrimaryContainer.withOpacity(0.9)
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: isDark 
                    ? colorScheme.onPrimaryContainer.withOpacity(0.9)
                    : colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getModeText() {
    switch (widget.searchMode) {
      case SearchMode.eng:
        return 'ENG';
      case SearchMode.jpn:
        return 'JPN';
      case SearchMode.mtg:
        return 'MTG';
    }
  }
  
  void _showSearchModeMenu() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.search, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Search Database',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Image.asset('assets/images/pokemon_logo.png', height: 24),
              title: const Text('Pokémon TCG (English)'),
              subtitle: const Text('Search English Pokémon cards'),
              selected: widget.searchMode == SearchMode.eng,
              onTap: () {
                widget.onSearchModeChanged(SearchMode.eng);
                Navigator.pop(context);
              },
              trailing: widget.searchMode == SearchMode.eng
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : null,
            ),
            ListTile(
              leading: Image.asset('assets/images/pokemon_jp_logo.png', height: 24),
              title: const Text('Pokémon TCG (Japanese)'),
              subtitle: const Text('Search Japanese Pokémon cards'),
              selected: widget.searchMode == SearchMode.jpn,
              onTap: () {
                widget.onSearchModeChanged(SearchMode.jpn);
                Navigator.pop(context);
              },
              trailing: widget.searchMode == SearchMode.jpn
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : null,
            ),
            ListTile(
              leading: Image.asset('assets/images/mtg_logo.png', height: 24),
              title: const Text('Magic: The Gathering'),
              subtitle: const Text('Search MTG cards'),
              selected: widget.searchMode == SearchMode.mtg,
              onTap: () {
                widget.onSearchModeChanged(SearchMode.mtg);
                Navigator.pop(context);
              },
              trailing: widget.searchMode == SearchMode.mtg
                  ? Icon(Icons.check_circle, color: colorScheme.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
