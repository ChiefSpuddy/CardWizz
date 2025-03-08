import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math; // Add this import
import '../../constants/sets.dart';
import '../../constants/japanese_sets.dart';
import '../../constants/mtg_sets.dart';
import '../../screens/search_screen.dart';
import '../../utils/image_utils.dart';
import '../../constants/app_colors.dart';
import '../../widgets/mtg_set_icon.dart';

class SearchCategories extends StatefulWidget {
  final SearchMode searchMode;
  final Function(Map<String, dynamic>) onQuickSearch;

  const SearchCategories({
    Key? key,
    required this.searchMode,
    required this.onQuickSearch,
  }) : super(key: key);

  @override
  State<SearchCategories> createState() => _SearchCategoriesState();
}

class _SearchCategoriesState extends State<SearchCategories> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  int _expandedIndex = 0;
  Brightness? _previousBrightness;
  
  // Define the missing category getters
  final List<Map<String, dynamic>> _pokemonCategories = [
    {'title': 'Featured', 'type': 'header'},
    {'title': 'Popular Sets', 'type': 'sets'},
    {'title': 'Recent Sets', 'type': 'sets'},
    
    {'title': 'Special Searches', 'type': 'header'},
    {'title': 'All Cards', 'query': '', 'icon': '🃏', 'type': 'search'},
    {'title': 'Most Valuable', 'query': 'cardmarket.prices.averageSellPrice:[20 TO 100000] -rarity:rare -supertype:trainer', 'icon': '💰', 'type': 'search', 'isValueSearch': true},
    {'title': 'Alt Arts', 'query': 'name:*alt* OR name:*gallery* OR name:*illustration*', 'icon': '🎨', 'type': 'search'},
    {'title': 'Full Arts', 'query': 'name:*full art*', 'icon': '🖼️', 'type': 'search'},
    {'title': 'Rainbow Cards', 'query': 'name:rainbow rare', 'icon': '🌈', 'type': 'search'},
    {'title': 'Gold Cards', 'query': 'name:*gold* -name:golden', 'icon': '✨', 'type': 'search'},
  ];
  
  final List<Map<String, dynamic>> _mtgCategories = [
    {'title': 'Featured', 'type': 'header'},
    {'title': 'Standard Sets', 'type': 'sets'},
    {'title': 'Commander Sets', 'type': 'sets'},
    
    {'title': 'Special Searches', 'type': 'header'},
    {'title': 'All Cards', 'query': '', 'icon': '🃏', 'type': 'search'},
    {'title': 'Most Valuable', 'query': 'usd>=50', 'icon': '💰', 'type': 'search', 'isValueSearch': true},
    {'title': 'Mythic Rares', 'query': 'r:mythic', 'icon': '🌟', 'type': 'search'},
    {'title': 'Legends', 'query': 't:legend', 'icon': '👑', 'type': 'search'},
    {'title': 'Planeswalkers', 'query': 't:planeswalker', 'icon': '🔮', 'type': 'search'},
    {'title': 'Showcase Arts', 'query': 'is:showcase', 'icon': '🖼️', 'type': 'search'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(SearchCategories oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchMode != widget.searchMode) {
      _expandedIndex = 0;
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Reset animation when theme changes to ensure proper display
    final brightness = Theme.of(context).brightness;
    if (_previousBrightness != brightness) {
      _previousBrightness = brightness;
      _resetAnimation();
    }
  }
  
  void _resetAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Define the eras based on search mode
    final sets = _getSetsForCurrentMode();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
            )),
            child: child,
          ),
        );
      },
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sets.length,
        itemBuilder: (context, index) {
          final era = sets[index];
          final isExpanded = _expandedIndex == index;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedIndex = isExpanded ? -1 : index;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isExpanded 
                        ? _getCategoryHeaderColor(widget.searchMode, true) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        color: isExpanded 
                            ? Colors.white 
                            : Theme.of(context).colorScheme.onBackground,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        era['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isExpanded 
                              ? Colors.white 
                              : Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(era['sets'] as Map<String, Map<String, dynamic>>).length} sets',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpanded 
                              ? Colors.white70 
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0),
                secondChild: Container(
                  height: 110, // Reduced height
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: (era['sets'] as Map<String, Map<String, dynamic>>).length,
                    itemBuilder: (context, index) {
                      final set = (era['sets'] as Map<String, Map<String, dynamic>>)
                          .entries.toList()[index];
                      
                      // Fix: Use the 'name' field from the set value rather than the key
                      return _buildSetCard(
                        context,
                        {
                          'name': set.value['name'] ?? set.key, // Use full name stored in 'name' field
                          'query': 'set.id:${set.value['code']}',
                          'icon': set.value['icon'],
                          'year': set.value['year'],
                          'logo': set.value['logo'],
                        },
                      );
                    },
                  ),
                ),
                crossFadeState: isExpanded 
                    ? CrossFadeState.showSecond 
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getSetsForCurrentMode() {
    switch (widget.searchMode) {
      case SearchMode.eng:
        return [
          {'title': 'Latest Sets', 'sets': PokemonSets.scarletViolet},
          {'title': 'Sword & Shield', 'sets': PokemonSets.swordShield},
          {'title': 'Sun & Moon', 'sets': PokemonSets.sunMoon},
          {'title': 'XY Series', 'sets': PokemonSets.xy},
          {'title': 'Black & White', 'sets': PokemonSets.blackWhite},
          {'title': 'HeartGold SoulSilver', 'sets': PokemonSets.heartGoldSoulSilver},
          {'title': 'Diamond & Pearl', 'sets': PokemonSets.diamondPearl},
          {'title': 'EX Series', 'sets': PokemonSets.ex},
          {'title': 'e-Card Series', 'sets': PokemonSets.eCard},
          {'title': 'Classic WOTC', 'sets': PokemonSets.classic},
        ];
      case SearchMode.mtg:
        return [
          {'title': 'Standard Sets', 'sets': _createSetMap(MtgSets.standard)},
          {'title': 'Commander Sets', 'sets': _createSetMap(MtgSets.commander)},
          {'title': 'Special & Masters', 'sets': _createSetMap(MtgSets.special)},
          {'title': 'Modern Sets', 'sets': _createSetMap(MtgSets.modern)},
          {'title': 'Pioneer Sets', 'sets': _createSetMap(MtgSets.pioneer)},
          {'title': 'Legacy Sets', 'sets': _createSetMap(MtgSets.legacy)},
          {'title': 'Classic Sets', 'sets': _createSetMap(MtgSets.classic)},
        ];
    }
  }

  // Helper method to convert list format to map format for MTG sets
  Map<String, Map<String, dynamic>> _createSetMap(Map<String, Map<String, dynamic>> sets) {
    return sets;
  }

  // Add the previously missing methods
  Map<String, dynamic> _buildCategoryHeader(BuildContext context, String title) {
    return {'title': title, 'type': 'header'};
  }

  Map<String, dynamic> _buildCategoryRow(BuildContext context, List<Map<String, dynamic>> sets) {
    // Convert sets list to the format expected by the UI
    final Map<String, Map<String, dynamic>> setsMap = {};
    
    for (final set in sets) {
      setsMap[set['code']] = {
        'name': set['name'],
        'code': set['code'],
        'year': set['year'] ?? '',
        'logo': set['logo'],
        'query': set['query'],
      };
    }
    
    return {'title': '', 'sets': setsMap, 'type': 'sets'};
  }

  Color _getCategoryHeaderColor(SearchMode mode, bool isExpanded) {
    if (!isExpanded) return Colors.transparent;
    
    switch (mode) {
      case SearchMode.eng:
        return AppColors.primaryPokemon;
      case SearchMode.mtg:
        return AppColors.primaryMtg;
    }
  }

  Widget _buildSetCard(BuildContext context, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final query = item['query'] as String? ?? '';
    final isSetQuery = query.startsWith('set.id:');
    
    // Extract set code
    String? setCode;
    if (isSetQuery) {
      setCode = query.replaceAll('set.id:', '').trim();
    }

    // Get the full set name - THIS IS THE KEY CHANGE
    final String displayName = item['name'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: isDark ? AppColors.searchBarDark : AppColors.searchBarLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          
          // Don't show snackbar anymore, our skeleton UI is better feedback
          // Instead, immediately call the search function
          widget.onQuickSearch(item);
          
          // Add debug log
          debugPrint('Set card tapped: ${item['name']} with query: ${item['query']}');
        },
        child: SizedBox(
          width: 100,
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Icon area
                Expanded(
                  flex: 1,
                  child: widget.searchMode == SearchMode.mtg && setCode != null
                    ? MtgSetIcon(
                        setCode: setCode,
                        size: 40,
                      )
                    : _buildStandardSetLogo(context, item, setCode, colorScheme),
                ),
                
                // Name area - DISPLAYING THE FULL NAME HERE
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      displayName,  // Using the full set name
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                // Year if available
                if (item['year'] != null)
                  Text(
                    item['year'].toString(),
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardSetLogo(BuildContext context, Map<String, dynamic> item, String? setCode, ColorScheme colorScheme) {
    // For Pokemon sets, use the Pokemon TCG API
    if (setCode != null) {
      final logoUrl = CardImageUtils.getPokemonSetLogo(setCode);

      return Image.network(
        logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) {
          print('Error loading set logo for ${item['name']}: $error');
          return Text(
            item['icon'] ?? '📦',
            style: TextStyle(
              fontSize: 20,
              color: colorScheme.primary.withOpacity(0.8)
            ),
          );
        },
      );
    }
    
    // Fallback
    return Text(
      item['icon'] ?? '📦',
      style: TextStyle(
        fontSize: 20,
        color: colorScheme.primary.withOpacity(0.8)
      ),
    );
  }

  // UPDATED: Return categories based on search mode (fixed)
  List<Map<String, dynamic>> get _categories {
    switch (widget.searchMode) {
      case SearchMode.eng:
        return _pokemonCategories;
      case SearchMode.mtg:
        return _mtgCategories;
    }
  }

  // UPDATED: Return sets based on search mode (fixed)
  List<Map<String, dynamic>> _getSetsForCategory(String category) {
    switch (widget.searchMode) {
      case SearchMode.eng:
        return PokemonSets.getSetsForCategory(category);
      case SearchMode.mtg:
        return MtgSets.getSetsForCategory(category);
    }
  }

  // UPDATED: Get logo based on search mode (fixed)
  Widget _getCategoryLogo() {
    final logoUrl = widget.searchMode == SearchMode.mtg
        ? 'assets/icons/mtg_logo.png'
        : 'assets/icons/pokemon_logo.png';
        
    return Image.asset(
      logoUrl,
      height: 40,
      fit: BoxFit.contain,
    );
  }
}
