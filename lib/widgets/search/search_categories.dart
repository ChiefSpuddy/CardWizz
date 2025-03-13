import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // Add this import for HapticFeedback
import '../../utils/image_utils.dart';
import '../../services/logging_service.dart'; // Fix import path
import '../../constants/sets.dart';
import '../../constants/japanese_sets.dart';
import '../../constants/mtg_sets.dart';
import '../../screens/search_screen.dart';
import '../../widgets/mtg_set_icon.dart';
import '../../constants/app_colors.dart';  // Fix import path

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
  
  // Expanded section tracking - note Special Searches defaults to true (open)
  bool _isSpecialSearchesExpanded = true;
  bool _isRaritiesExpanded = false;
  bool _isSubtypesExpanded = false;
  bool _isTypesExpanded = false;
  
  // Define the main categories but move the special searches into their own list
  final List<Map<String, dynamic>> _pokemonCategories = [
    {'title': 'Featured', 'type': 'header'},
    {'title': 'Popular Sets', 'type': 'sets'},
    {'title': 'Recent Sets', 'type': 'sets'},
    
    // Advanced Categories Headers - these will be toggles
    {'title': 'Special Searches', 'type': 'toggle_header', 'toggleKey': 'special'},
    {'title': 'All Rarities', 'type': 'toggle_header', 'toggleKey': 'rarities'}, 
    {'title': 'All Subtypes', 'type': 'toggle_header', 'toggleKey': 'subtypes'},
    {'title': 'Pokémon Types', 'type': 'toggle_header', 'toggleKey': 'types'},
  ];
  
  // Special searches categories in their own list for the toggle
  final List<Map<String, dynamic>> _specialSearchCategories = [
    // Most Valuable entry removed
    {'title': 'Special Illustration Rare', 'query': 'rarity:"Special Illustration Rare" OR rarity:"Illustration Rare" OR name:"special illustration rare"', 'icon': '🌟', 'type': 'search'},
    {'title': 'Rainbow Rare', 'query': 'rarity:"Rare Rainbow"', 'icon': '🌈', 'type': 'search'},
    {'title': 'Secret Rare', 'query': 'rarity:"Rare Secret"', 'icon': '🔮', 'type': 'search'},
    {'title': 'Ultra Rare', 'query': 'rarity:"Rare Ultra"', 'icon': '💎', 'type': 'search'},
    {'title': 'Full Art', 'query': 'name:*"full art"* OR name:*"FA"*', 'icon': '🖼️', 'type': 'search'},
    // Amazing Rare entry removed
    {'title': 'Trainer Gallery', 'query': 'set.id:*tg*', 'icon': '👤', 'type': 'search'}, 
    {'title': 'Holo Rare', 'query': 'rarity:"Rare Holo"', 'icon': '🔮', 'type': 'search'},
    {'title': 'Common & Uncommon', 'query': 'rarity:common OR rarity:uncommon', 'icon': '📋', 'type': 'search'},
  ];
  
  // Additional category lists that will be hidden behind toggles
  final List<Map<String, dynamic>> _rarityCategories = [
    // Modern Rares
    {'title': 'Rare V', 'query': 'rarity:"Rare Holo V"', 'icon': '⭐', 'type': 'search'},
    {'title': 'Rare VMAX', 'query': 'rarity:"Rare Holo VMAX"', 'icon': '⭐', 'type': 'search'},
    {'title': 'Rare VSTAR', 'query': 'rarity:"Rare Holo VSTAR"', 'icon': '⭐', 'type': 'search'},
    {'title': 'Shiny Rare', 'query': 'rarity:"Shiny Rare"', 'icon': '✨', 'type': 'search'},
    {'title': 'Shiny Ultra Rare', 'query': 'rarity:"Shiny Ultra Rare"', 'icon': '✨', 'type': 'search'},
    {'title': 'Radiant Rare', 'query': 'rarity:"Radiant Rare"', 'icon': '🌟', 'type': 'search'},
    {'title': 'Promo Cards', 'query': 'rarity:"Promo"', 'icon': '🎁', 'type': 'search'},
    
    // Legacy Rares
    {'title': 'Basic Rare', 'query': 'rarity:"Rare"', 'icon': '⭐', 'type': 'search'},
    {'title': 'Double Rare', 'query': 'rarity:"Double Rare"', 'icon': '⭐⭐', 'type': 'search'},
    {'title': 'Classic Collection', 'query': 'rarity:"Classic Collection"', 'icon': '🏆', 'type': 'search'},
    {'title': 'ACE SPEC Rare', 'query': 'rarity:"ACE SPEC Rare"', 'icon': '🏅', 'type': 'search'},
    {'title': 'LEGEND', 'query': 'rarity:"LEGEND"', 'icon': '👑', 'type': 'search'},
    {'title': 'Rare BREAK', 'query': 'rarity:"Rare BREAK"', 'icon': '💥', 'type': 'search'},
    {'title': 'Rare Prism Star', 'query': 'rarity:"Rare Prism Star"', 'icon': '🌠', 'type': 'search'},
    {'title': 'Rare Shining', 'query': 'rarity:"Rare Shining"', 'icon': '✨', 'type': 'search'},
    {'title': 'Rare Prime', 'query': 'rarity:"Rare Prime"', 'icon': '🔝', 'type': 'search'},
    {'title': 'Rare ACE', 'query': 'rarity:"Rare ACE"', 'icon': '🏅', 'type': 'search'},
    {'title': 'Rare Holo Star', 'query': 'rarity:"Rare Holo Star"', 'icon': '⭐', 'type': 'search'},
    {'title': 'Rare Holo LV.X', 'query': 'rarity:"Rare Holo LV.X"', 'icon': '⬆️', 'type': 'search'},
    {'title': 'Rare Holo EX', 'query': 'rarity:"Rare Holo EX"', 'icon': '💪', 'type': 'search'},
    {'title': 'Rare Holo GX', 'query': 'rarity:"Rare Holo GX"', 'icon': '🌈', 'type': 'search'},
    {'title': 'Rare Shiny GX', 'query': 'rarity:"Rare Shiny GX"', 'icon': '✨', 'type': 'search'},
    {'title': 'Trainer Gallery Rare', 'query': 'rarity:"Trainer Gallery Rare Holo"', 'icon': '👤', 'type': 'search'},
  ];
  
  final List<Map<String, dynamic>> _subtypeCategories = [
    // Card Types
    {'title': 'Basic', 'query': 'subtypes:Basic', 'icon': '🔵', 'type': 'search'},
    {'title': 'Stage 1', 'query': 'subtypes:"Stage 1"', 'icon': '🟡', 'type': 'search'},
    {'title': 'Stage 2', 'query': 'subtypes:"Stage 2"', 'icon': '🔴', 'type': 'search'},
    {'title': 'BREAK', 'query': 'subtypes:BREAK', 'icon': '💥', 'type': 'search'},
    {'title': 'LEGEND', 'query': 'subtypes:LEGEND', 'icon': '👑', 'type': 'search'},
    {'title': 'Restored', 'query': 'subtypes:Restored', 'icon': '🦴', 'type': 'search'},
    {'title': 'Baby', 'query': 'subtypes:Baby', 'icon': '👶', 'type': 'search'},
    {'title': 'Level-Up', 'query': 'subtypes:"Level-Up"', 'icon': '⬆️', 'type': 'search'},
    
    // Special Types
    {'title': 'EX Cards', 'query': 'subtypes:EX', 'icon': '💪', 'type': 'search'},
    {'title': 'GX Cards', 'query': 'subtypes:GX', 'icon': '🌈', 'type': 'search'},
    {'title': 'V Cards', 'query': 'subtypes:V', 'icon': '⚡', 'type': 'search'},
    {'title': 'VMAX Cards', 'query': 'subtypes:VMAX', 'icon': '⚡⚡', 'type': 'search'},
    {'title': 'MEGA', 'query': 'subtypes:MEGA', 'icon': '🔄', 'type': 'search'},
    {'title': 'TAG TEAM', 'query': 'subtypes:"TAG TEAM"', 'icon': '👥', 'type': 'search'},
    {'title': 'Radiant', 'query': 'subtypes:Radiant', 'icon': '☀️', 'type': 'search'},
    {'title': 'Single Strike', 'query': 'subtypes:"Single Strike"', 'icon': '👊', 'type': 'search'},
    {'title': 'Rapid Strike', 'query': 'subtypes:"Rapid Strike"', 'icon': '🥊', 'type': 'search'},

    // Trainer Types
    {'title': 'Supporter', 'query': 'subtypes:Supporter', 'icon': '🧑‍🏫', 'type': 'search'},
    {'title': 'Stadium', 'query': 'subtypes:Stadium', 'icon': '🏟️', 'type': 'search'},
    {'title': 'Item', 'query': 'subtypes:Item', 'icon': '🧪', 'type': 'search'},
    {'title': 'Pokémon Tool', 'query': 'subtypes:"Pokémon Tool"', 'icon': '🔧', 'type': 'search'},
    {'title': 'Technical Machine', 'query': 'subtypes:"Technical Machine"', 'icon': '💿', 'type': 'search'},
    {'title': 'Special', 'query': 'subtypes:Special', 'icon': '✨', 'type': 'search'},
  ];
  
  // Add new type categories list 
  final List<Map<String, dynamic>> _typeCategories = [
    {'title': 'Colorless', 'query': 'types:Colorless', 'icon': '⚪', 'type': 'search'},
    {'title': 'Darkness', 'query': 'types:Darkness', 'icon': '⚫', 'type': 'search'},
    {'title': 'Dragon', 'query': 'types:Dragon', 'icon': '🐉', 'type': 'search'},
    {'title': 'Fairy', 'query': 'types:Fairy', 'icon': '🧚', 'type': 'search'},
    {'title': 'Fighting', 'query': 'types:Fighting', 'icon': '👊', 'type': 'search'},
    {'title': 'Fire', 'query': 'types:Fire', 'icon': '🔥', 'type': 'search'},
    {'title': 'Grass', 'query': 'types:Grass', 'icon': '🌿', 'type': 'search'},
    {'title': 'Lightning', 'query': 'types:Lightning', 'icon': '⚡', 'type': 'search'},
    {'title': 'Metal', 'query': 'types:Metal', 'icon': '🔩', 'type': 'search'},
    {'title': 'Psychic', 'query': 'types:Psychic', 'icon': '🔮', 'type': 'search'},
    {'title': 'Water', 'query': 'types:Water', 'icon': '💧', 'type': 'search'},
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
    
    // Remove the rarities fetching call
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Set Categories Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Set Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
          
          // Existing Set Categories - APPEAR FIRST NOW
          ListView.builder(
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
          
          // Divider between sections
          const Divider(height: 32, indent: 16, endIndent: 16),
          
          // Advanced sections - only if in Pokemon mode
          if (widget.searchMode == SearchMode.eng)
            _buildAdvancedCategoriesSections(context),
        ],
      ),
    );
  }

  // Add this new method to build the advanced categories sections
  Widget _buildAdvancedCategoriesSections(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Special Searches Section with toggle (default: expanded)
        _buildToggleSection(
          context,
          'Special Searches',
          _isSpecialSearchesExpanded, 
          (expanded) => setState(() => _isSpecialSearchesExpanded = expanded),
          _specialSearchCategories,
        ),
        
        // Rarities Section with toggle
        _buildToggleSection(
          context,
          'All Rarities',
          _isRaritiesExpanded, 
          (expanded) => setState(() => _isRaritiesExpanded = expanded),
          _rarityCategories,
        ),
        
        // Subtypes Section with toggle
        _buildToggleSection(
          context,
          'All Subtypes',
          _isSubtypesExpanded,
          (expanded) => setState(() => _isSubtypesExpanded = expanded),
          _subtypeCategories,
        ),
        
        // Types Section with toggle (new)
        _buildToggleSection(
          context,
          'Pokémon Types',
          _isTypesExpanded,
          (expanded) => setState(() => _isTypesExpanded = expanded),
          _typeCategories,
        ),
      ],
    );
  }
  
  // Add this method to build a toggle section
  Widget _buildToggleSection(
    BuildContext context, 
    String title, 
    bool isExpanded, 
    Function(bool) onToggle,
    List<Map<String, dynamic>> categories,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle header with improved styling to match set toggles
        InkWell(
          onTap: () => onToggle(!isExpanded),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isExpanded 
                  ? _getCategoryHeaderColor(widget.searchMode, true) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isExpanded 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isExpanded 
                      ? Colors.white70 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        
        // Content - only show when expanded
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.7,  // Make tiles a bit wider for better layout
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryTile(context, category);
              },
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        
        // Divider after section
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 16, 
              color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.1),
              thickness: 1,
            ),
          ),
      ],
    );
  }

  // NEW METHOD: Build category tile
  Widget _buildCategoryTile(BuildContext context, Map<String, dynamic> category) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Ensure category has name property for search_screen.dart
    if (!category.containsKey('name')) {
      category['name'] = category['title'];
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark 
          ? AppColors.searchBarDark.withOpacity(0.8)
          : AppColors.searchBarLight,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onQuickSearch(category);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.searchMode, category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    category['icon'] as String? ?? '🔍',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category['title'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // New helper method to get category colors
  Color _getCategoryColor(SearchMode mode, Map<String, dynamic> category) {
    // Get primary color based on mode
    final baseColor = mode == SearchMode.eng 
        ? AppColors.primaryPokemon 
        : AppColors.primaryMtg;
    
    // For rarity categories, use specific colors
    final title = category['title'].toString().toLowerCase();
    
    if (title.contains('rainbow') || title.contains('rare rainbow')) {
      return Colors.purple;
    } else if (title.contains('secret') || title.contains('rare secret')) {
      return Colors.deepPurple;
    } else if (title.contains('ultra') || title.contains('rare ultra')) {
      return Colors.blue;
    } else if (title.contains('full art')) {
      return Colors.indigo;
    } else if (title.contains('amazing')) {
      return Colors.teal;
    } else if (title.contains('holo')) {
      return Colors.cyan;
    } else if (title.contains('common') || title.contains('uncommon')) {
      return Colors.grey;
    }
    
    // For type categories
    if (title == 'fire') {
      return Colors.red;
    } else if (title == 'water') {
      return Colors.blue;
    } else if (title == 'grass') {
      return Colors.green;
    } else if (title == 'lightning') {
      return Colors.amber;
    } else if (title == 'psychic') {
      return Colors.purple;
    } else if (title == 'fighting') {
      return Colors.brown;
    }
    
    // Default to base color
    return baseColor;
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
          LoggingService.debug('Set card tapped: ${item['name']} with query: ${item['query']}');
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
          LoggingService.debug('Error loading set logo for ${item['name']}: $error');
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
}
