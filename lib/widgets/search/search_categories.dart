import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/sets.dart';
import '../../constants/japanese_sets.dart';
import '../../constants/mtg_sets.dart';
import '../../screens/search_screen.dart';
import '../../utils/image_utils.dart';
import '../../constants/app_colors.dart';

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
                      return _buildSetCard(
                        context,
                        {
                          'name': set.key,
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
      case SearchMode.jpn:
        return [
          {'title': 'Latest Sets', 'sets': JapaneseSets.scarletViolet},
          {'title': 'Sword & Shield', 'sets': JapaneseSets.swordShield},
          {'title': 'Sun & Moon', 'sets': JapaneseSets.sunMoon},
        ];
      case SearchMode.mtg:
        return [
          {'title': 'Standard Sets', 'sets': MtgSets.standard},
          {'title': 'Modern Sets', 'sets': MtgSets.modern},
          {'title': 'Legacy Sets', 'sets': MtgSets.legacy},
          {'title': 'Pioneer Sets', 'sets': <String, Map<String, dynamic>>{}},
          {'title': 'Specialty Sets', 'sets': <String, Map<String, dynamic>>{}},
        ];
    }
  }

  Color _getCategoryHeaderColor(SearchMode mode, bool isExpanded) {
    if (!isExpanded) return Colors.transparent;
    
    switch (mode) {
      case SearchMode.eng:
        return AppColors.primaryPokemon;
      case SearchMode.jpn:
        return AppColors.primaryJapanese;
      case SearchMode.mtg:
        return AppColors.primaryMtg;
    }
  }

  Widget _buildSetCard(BuildContext context, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final query = item['query'] as String? ?? '';
    final isSetQuery = query.startsWith('set.id:');
    
    // Get logo URL based on query type
    String? logoUrl;
    if (item.containsKey('logo') && item['logo'] != null) {
      logoUrl = item['logo'] as String;
    } else if (isSetQuery) {
      final setCode = query.replaceAll('set.id:', '').trim();
      // Use Pokemon TCG API CDN for Pokemon sets
      if (widget.searchMode != SearchMode.mtg) {
        logoUrl = 'https://images.pokemontcg.io/$setCode/logo.png';
      } else {
        // Keep Scryfall for MTG sets
        logoUrl = 'https://c2.scryfall.com/file/scryfall-symbols/sets/$setCode.svg';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: isDark ? AppColors.searchBarDark : AppColors.searchBarLight,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onQuickSearch(item);
        },
        child: SizedBox( // Changed from Container to SizedBox
          width: 100,
          height: 100, // Added fixed height
          child: Padding(
            padding: const EdgeInsets.all(8), // Reduced padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (logoUrl != null)
                  Expanded(
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) {
                        print('Error loading set symbol for ${item['name']}: $error');
                        return Text(
                          item['icon'] ?? '📦',
                          style: TextStyle(
                            fontSize: 20, // Reduced font size
                            color: colorScheme.primary.withOpacity(0.8)
                          ),
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8), // Reduced padding
                    child: Text(
                      item['icon'] ?? '📦',
                      style: const TextStyle(fontSize: 20), // Reduced font size
                    ),
                  ),
                if (item['name'] != null)
                  Flexible( // Added Flexible
                    child: Text(
                      item['name'] ?? '',
                      style: TextStyle(
                        fontSize: 10, // Reduced font size
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (item['year'] != null)
                  Text(
                    item['year'].toString(),
                    style: TextStyle(
                      fontSize: 9, // Reduced font size
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
}
