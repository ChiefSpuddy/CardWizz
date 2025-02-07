import 'package:flutter/material.dart';
import 'dart:async';
import '../services/tcg_api_service.dart';
import '../services/search_history_service.dart';
import '../screens/card_details_screen.dart';
import '../models/tcg_card.dart';
import '../widgets/card_grid_item.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/card_styles.dart';
import '../constants/colors.dart';  // Add this import
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';  // Add this import
import '../constants/layout.dart';  // Add this import

// Move enum outside the class
enum SearchMode { cards, sets }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _apiService = TcgApiService();
  final _searchController = TextEditingController();
  List<TcgCard>? _searchResults;
  bool _isLoading = false;
  String _currentSort = 'cardmarket.prices.averageSellPrice';
  bool _sortAscending = false;
  SearchHistoryService? _searchHistory;
  bool _isHistoryLoading = true;
  bool _isInitialSearch = true;
  bool _showCategories = true; // Add this

  // Replace all the old search constants with new organized ones
  static const searchCategories = {
    'vintage': [
      {'name': 'Base Set', 'icon': '📦', 'year': '1999', 'query': 'set.id:base1', 'description': 'Original Pokemon TCG set'},
      {'name': 'Jungle', 'icon': '🌿', 'year': '1999', 'query': 'set.id:base2', 'description': 'Second Base Set expansion'},
      {'name': 'Fossil', 'icon': '🦴', 'year': '1999', 'query': 'set.id:base3', 'description': 'Ancient Pokemon cards'},
      {'name': 'Base Set 2', 'icon': '2️⃣', 'year': '2000', 'query': 'set.id:base4', 'description': 'Base Set revision'},
      {'name': 'Team Rocket', 'icon': '🚀', 'year': '2000', 'query': 'set.id:base5', 'description': 'Evil team themed set'},
      {'name': 'Legendary Collection', 'icon': '👑', 'year': '2002', 'query': 'set.id:base6', 'description': 'Best of Base-Fossil'},
      {'name': 'Gym Heroes', 'icon': '🏃', 'year': '2000', 'query': 'set.id:gym1', 'description': 'Gym Leader cards'},
      {'name': 'Gym Challenge', 'icon': '🏆', 'year': '2000', 'query': 'set.id:gym2', 'description': 'Gym Leader cards'},
      {'name': 'Neo Genesis', 'icon': '✨', 'year': '2000', 'query': 'set.id:neo1', 'description': 'First Neo series set'},
      {'name': 'Neo Discovery', 'icon': '🔍', 'year': '2001', 'query': 'set.id:neo2', 'description': 'Neo Discovery set'},
      {'name': 'Neo Revelation', 'icon': '📜', 'year': '2001', 'query': 'set.id:neo3', 'description': 'Neo Revelation set'},
      {'name': 'Neo Destiny', 'icon': '⭐', 'year': '2002', 'query': 'set.id:neo4', 'description': 'Neo Destiny set'},
      {'name': 'Southern Islands', 'icon': '🏝️', 'year': '2001', 'query': 'set.id:si1', 'description': 'Tropical promo set'},
      {'name': 'Expedition', 'icon': '🗺️', 'year': '2002', 'query': 'set.id:ecard1', 'description': 'First e-Card set'},
      {'name': 'Aquapolis', 'icon': '🌊', 'year': '2003', 'query': 'set.id:ecard2', 'description': 'Second e-Card set'},
      {'name': 'Skyridge', 'icon': '🌅', 'year': '2003', 'query': 'set.id:ecard3', 'description': 'Final e-Card set'},
    ],
    'modern': [
      {'name': 'Prismatic Evolution', 'icon': '💎', 'release': '2024', 'query': 'set.id:sv8pt5', 'description': 'Special set'},
      {'name': 'Surging Sparks', 'icon': '⚡', 'release': '2024', 'query': 'set.id:sv8', 'description': 'Electric themed set'},
      {'name': '151', 'icon': '🌟', 'release': '2023', 'query': 'set.id:sv3pt5', 'description': 'Original 151 Pokemon'},
      {'name': 'Temporal Forces', 'icon': '⌛', 'release': '2024', 'query': 'set.id:sv5', 'description': 'Time themed set'},
      {'name': 'Paradox Rift', 'icon': '🌀', 'release': '2023', 'query': 'set.id:sv4', 'description': 'Paradox Pokemon'},
      {'name': 'Obsidian Flames', 'icon': '🔥', 'release': '2023', 'query': 'set.id:sv3', 'description': 'Fire themed set'},
      {'name': 'Paldea Evolved', 'icon': '🌟', 'release': '2023', 'query': 'set.id:sv2', 'description': 'Paldean Pokemon'},
      {'name': 'Scarlet & Violet', 'icon': '⚔️', 'release': '2023', 'query': 'set.id:sv1', 'description': 'Base SV set'},
    ],
    'swsh': [  // Reorganized Sword & Shield sets
      {'name': 'Crown Zenith', 'icon': '👑', 'release': '2023', 'query': 'set.id:swsh12pt5', 'description': 'Final SwSh set'},
      {'name': 'Silver Tempest', 'icon': '⚡', 'release': '2022', 'query': 'set.id:swsh12', 'description': 'Silver themed'},
      {'name': 'Lost Origin', 'icon': '🌌', 'release': '2022', 'query': 'set.id:swsh11', 'description': 'Lost Zone cards'},
      {'name': 'Astral Radiance', 'icon': '✨', 'release': '2022', 'query': 'set.id:swsh10', 'description': 'Astral cards'},
      {'name': 'Brilliant Stars', 'icon': '💫', 'release': '2022', 'query': 'set.id:swsh9', 'description': 'Brilliant cards'},
      {'name': 'Evolving Skies', 'icon': '🌤️', 'release': '2021', 'query': 'set.id:swsh7', 'description': 'Dragon themed'},
      {'name': 'Chilling Reign', 'icon': '❄️', 'release': '2021', 'query': 'set.id:swsh6', 'description': 'Ice themed'},
      {'name': 'Battle Styles', 'icon': '⚔️', 'release': '2021', 'query': 'set.id:swsh5', 'description': 'Battle themed'},
      {'name': 'Shining Fates', 'icon': '✨', 'release': '2021', 'query': 'set.id:swsh45', 'description': 'Shiny Pokemon'},
      {'name': 'Vivid Voltage', 'icon': '⚡', 'release': '2020', 'query': 'set.id:swsh4', 'description': 'Electric themed'},
      {'name': 'Darkness Ablaze', 'icon': '🔥', 'release': '2020', 'query': 'set.id:swsh3', 'description': 'Fire themed'},
      {'name': 'Rebel Clash', 'icon': '🛡️', 'release': '2020', 'query': 'set.id:swsh2', 'description': 'Rebellion themed'},
      {'name': "Champion's Path", 'icon': '🏆', 'release': '2020', 'query': 'set.id:swsh35', 'description': 'Champion themed'},
    ],
    'sm': [  // Add Sun & Moon era
      {'name': 'Lost Thunder', 'icon': '⚡', 'release': '2018', 'query': 'set.id:sm8', 'description': 'Lost Thunder set'},
      {'name': 'Ultra Prism', 'icon': '💠', 'release': '2018', 'query': 'set.id:sm5', 'description': 'Ultra Prism set'},
      {'name': 'Burning Shadows', 'icon': '🔥', 'release': '2017', 'query': 'set.id:sm3', 'description': 'Burning Shadows set'},
      {'name': 'Guardians Rising', 'icon': '🛡️', 'release': '2017', 'query': 'set.id:sm2', 'description': 'Guardians Rising set'},
      {'name': 'Sun & Moon Base', 'icon': '☀️', 'release': '2017', 'query': 'set.id:sm1', 'description': 'Base Sun & Moon set'},
      {'name': 'Team Up', 'icon': '🤝', 'release': '2019', 'query': 'set.id:sm9', 'description': 'Team Up set'},
      {'name': 'Unbroken Bonds', 'icon': '🔗', 'release': '2019', 'query': 'set.id:sm10', 'description': 'Unbroken Bonds set'},
      {'name': 'Unified Minds', 'icon': '🧠', 'release': '2019', 'query': 'set.id:sm11', 'description': 'Unified Minds set'},
      {'name': 'Cosmic Eclipse', 'icon': '🌌', 'release': '2019', 'query': 'set.id:sm12', 'description': 'Cosmic Eclipse set'},
      {'name': 'Hidden Fates', 'icon': '🎯', 'release': '2019', 'query': 'set.id:sm115', 'description': 'Hidden Fates set'},
    ],
    'ex': [  // Add EX Series
      {'name': 'Ruby & Sapphire', 'icon': '💎', 'year': '2003', 'query': 'set.id:ex1', 'description': 'EX Ruby & Sapphire'},
      {'name': 'Sandstorm', 'icon': '🏜️', 'year': '2003', 'query': 'set.id:ex2', 'description': 'EX Sandstorm'},
      {'name': 'Dragon', 'icon': '🐉', 'year': '2003', 'query': 'set.id:ex3', 'description': 'EX Dragon'},
      {'name': 'Hidden Legends', 'icon': '🗿', 'year': '2004', 'query': 'set.id:ex5', 'description': 'EX Hidden Legends'},
      {'name': 'FireRed & LeafGreen', 'icon': '🔥', 'year': '2004', 'query': 'set.id:ex6', 'description': 'EX FireRed & LeafGreen'},
      {'name': 'Team Rocket Returns', 'icon': '🚀', 'year': '2004', 'query': 'set.id:ex7', 'description': 'EX Team Rocket Returns'},
      {'name': 'Deoxys', 'icon': '🧬', 'year': '2005', 'query': 'set.id:ex8', 'description': 'EX Deoxys'},
      {'name': 'Emerald', 'icon': '💚', 'year': '2005', 'query': 'set.id:ex9', 'description': 'EX Emerald'},
      {'name': 'Unseen Forces', 'icon': '👻', 'year': '2005', 'query': 'set.id:ex10', 'description': 'EX Unseen Forces'},
      {'name': 'Delta Species', 'icon': '🔮', 'year': '2005', 'query': 'set.id:ex11', 'description': 'EX Delta Species'},
      {'name': 'Legend Maker', 'icon': '📖', 'year': '2006', 'query': 'set.id:ex12', 'description': 'EX Legend Maker'},
      {'name': 'Holon Phantoms', 'icon': '🌌', 'year': '2006', 'query': 'set.id:ex13', 'description': 'EX Holon Phantoms'},
      {'name': 'Crystal Guardians', 'icon': '💎', 'year': '2006', 'query': 'set.id:ex14', 'description': 'EX Crystal Guardians'},
      {'name': 'Dragon Frontiers', 'icon': '🐲', 'year': '2006', 'query': 'set.id:ex15', 'description': 'EX Dragon Frontiers'},
      {'name': 'Power Keepers', 'icon': '⚡', 'year': '2007', 'query': 'set.id:ex16', 'description': 'EX Power Keepers'},
    ],
    'special': [
      {'name': 'Special Illustration', 'icon': '🎨', 'query': 'rarity:"Special Illustration Rare"', 'description': 'Special art cards'},
      {'name': 'Ancient', 'icon': '🗿', 'query': 'subtypes:ancient', 'description': 'Ancient variant cards'},
      {'name': 'Full Art', 'icon': '👤', 'query': 'subtypes:"Trainer Gallery" OR rarity:"Rare Ultra" -subtypes:VMAX', 'description': 'Full art cards'},
      {'name': 'Gold', 'icon': '✨', 'query': 'rarity:"Rare Secret"', 'description': 'Gold rare cards'},
    ],
    'popular': [
      {'name': 'Charizard', 'icon': '🔥', 'query': 'name:charizard', 'description': 'All Charizard cards'},
      {'name': 'Lugia', 'icon': '🌊', 'query': 'name:lugia', 'description': 'All Lugia cards'},
      {'name': 'Giratina', 'icon': '👻', 'query': 'name:giratina', 'description': 'All Giratina cards'},
      {'name': 'Pikachu', 'icon': '⚡', 'query': 'name:pikachu', 'description': 'All Pikachu cards'},
      {'name': 'Mewtwo', 'icon': '🧬', 'query': 'name:mewtwo', 'description': 'All Mewtwo cards'},
      {'name': 'Mew', 'icon': '💫', 'query': 'name:mew -name:mewtwo', 'description': 'All Mew cards'},
      {'name': 'Umbreon', 'icon': '🌙', 'query': 'name:umbreon', 'description': 'All Umbreon cards'},
    ],
    'xy': [  // Add XY Series
      {'name': 'XY Base Set', 'icon': '⚔️', 'release': '2014', 'query': 'set.id:xy1', 'description': 'XY Base Set'},
      {'name': 'Flashfire', 'icon': '🔥', 'release': '2014', 'query': 'set.id:xy2', 'description': 'Fire themed set'},
      {'name': 'Furious Fists', 'icon': '👊', 'release': '2014', 'query': 'set.id:xy3', 'description': 'Fighting themed'},
      {'name': 'Phantom Forces', 'icon': '👻', 'release': '2014', 'query': 'set.id:xy4', 'description': 'Ghost/Psychic themed'},
      {'name': 'Primal Clash', 'icon': '🌊', 'release': '2015', 'query': 'set.id:xy5', 'description': 'Primal Reversion'},
      {'name': 'Roaring Skies', 'icon': '🌪️', 'release': '2015', 'query': 'set.id:xy6', 'description': 'Flying themed'},
      {'name': 'Ancient Origins', 'icon': '🏺', 'release': '2015', 'query': 'set.id:xy7', 'description': 'Ancient traits'},
      {'name': 'BREAKthrough', 'icon': '💥', 'release': '2015', 'query': 'set.id:xy8', 'description': 'BREAK Evolution'},
      {'name': 'BREAKpoint', 'icon': '⚡', 'release': '2016', 'query': 'set.id:xy9', 'description': 'BREAK Evolution'},
      {'name': 'Fates Collide', 'icon': '🎲', 'release': '2016', 'query': 'set.id:xy10', 'description': 'Zygarde themed'},
      {'name': 'Steam Siege', 'icon': '🚂', 'release': '2016', 'query': 'set.id:xy11', 'description': 'Volcanion themed'},
      {'name': 'Evolutions', 'icon': '🧬', 'release': '2016', 'query': 'set.id:xy12', 'description': 'Base Set remake'},
      {'name': 'Generations', 'icon': '🌟', 'release': '2016', 'query': 'set.id:g1', 'description': '20th Anniversary'},
    ],

    'bw': [  // Add Black & White Series
      {'name': 'Black & White', 'icon': '⚫', 'release': '2011', 'query': 'set.id:bw1', 'description': 'BW Base Set'},
      {'name': 'Emerging Powers', 'icon': '💪', 'release': '2011', 'query': 'set.id:bw2', 'description': 'New Pokemon'},
      {'name': 'Noble Victories', 'icon': '🏆', 'release': '2011', 'query': 'set.id:bw3', 'description': 'Victory themed'},
      {'name': 'Next Destinies', 'icon': '🔮', 'release': '2012', 'query': 'set.id:bw4', 'description': 'Future themed'},
      {'name': 'Dark Explorers', 'icon': '🌑', 'release': '2012', 'query': 'set.id:bw5', 'description': 'Dark Pokemon'},
      {'name': 'Dragons Exalted', 'icon': '🐉', 'release': '2012', 'query': 'set.id:bw6', 'description': 'Dragon themed'},
      {'name': 'Boundaries Crossed', 'icon': '🌈', 'release': '2012', 'query': 'set.id:bw7', 'description': 'Black/White Kyurem'},
      {'name': 'Plasma Storm', 'icon': '⚡', 'release': '2013', 'query': 'set.id:bw8', 'description': 'Team Plasma'},
      {'name': 'Plasma Freeze', 'icon': '❄️', 'release': '2013', 'query': 'set.id:bw9', 'description': 'Team Plasma'},
      {'name': 'Plasma Blast', 'icon': '💥', 'release': '2013', 'query': 'set.id:bw10', 'description': 'Team Plasma'},
      {'name': 'Legendary Treasures', 'icon': '💎', 'release': '2013', 'query': 'set.id:bw11', 'description': 'Radiant Collection'},
    ],

    'hgss': [  // Add HeartGold & SoulSilver Series
      {'name': 'HeartGold SoulSilver', 'icon': '💗', 'release': '2010', 'query': 'set.id:hgss1', 'description': 'HGSS Base Set'},
      {'name': 'Unleashed', 'icon': '🔓', 'release': '2010', 'query': 'set.id:hgss2', 'description': 'Unleashed set'},
      {'name': 'Undaunted', 'icon': '🦁', 'release': '2010', 'query': 'set.id:hgss3', 'description': 'Undaunted set'},
      {'name': 'Triumphant', 'icon': '🏅', 'release': '2010', 'query': 'set.id:hgss4', 'description': 'Triumphant set'},
      {'name': 'Call of Legends', 'icon': '📞', 'release': '2011', 'query': 'set.id:col1', 'description': 'Shiny Pokemon'},
    ],

    'dp': [  // Add Diamond & Pearl Series
      {'name': 'Diamond & Pearl', 'icon': '💎', 'release': '2007', 'query': 'set.id:dp1', 'description': 'DP Base Set'},
      {'name': 'Mysterious Treasures', 'icon': '🗝️', 'release': '2007', 'query': 'set.id:dp2', 'description': 'Treasures set'},
      {'name': 'Secret Wonders', 'icon': '✨', 'release': '2007', 'query': 'set.id:dp3', 'description': 'Wonders set'},
      {'name': 'Great Encounters', 'icon': '🤝', 'release': '2008', 'query': 'set.id:dp4', 'description': 'Encounters set'},
      {'name': 'Majestic Dawn', 'icon': '🌅', 'release': '2008', 'query': 'set.id:dp5', 'description': 'Dawn set'},
      {'name': 'Legends Awakened', 'icon': '🐉', 'release': '2008', 'query': 'set.id:dp6', 'description': 'Legends set'},
      {'name': 'Stormfront', 'icon': '⛈️', 'release': '2008', 'query': 'set.id:dp7', 'description': 'Storm set'},
      {'name': 'Platinum', 'icon': '⚪', 'release': '2009', 'query': 'set.id:pl1', 'description': 'Platinum Base'},
      {'name': 'Rising Rivals', 'icon': '⚔️', 'release': '2009', 'query': 'set.id:pl2', 'description': 'Rivals set'},
      {'name': 'Supreme Victors', 'icon': '👑', 'release': '2009', 'query': 'set.id:pl3', 'description': 'Victors set'},
      {'name': 'Arceus', 'icon': '🔱', 'release': '2009', 'query': 'set.id:pl4', 'description': 'Arceus set'},
    ],
  };

  // Add these fields after other declarations
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  int _totalCards = 0;
  bool _hasMorePages = true;
  int _currentPage = 1;  // Keep only one declaration
  bool _isLoadingMore = false;

  // Add cache manager
  static const _maxConcurrentLoads = 3;
  final _loadingImages = <String>{};
  final _imageCache = <String, Image>{};
  final _loadQueue = <String>[];
  final Set<String> _loadingRequestedUrls = {};

  // Add field to track last query
  String? _lastQuery;

  // Add search mode state
  SearchMode _searchMode = SearchMode.cards;
  List<dynamic>? _setResults;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initSearchHistory();
    
    // Handle initial search if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['initialSearch'] != null) {
        _searchController.text = args['initialSearch'] as String;
        _performSearch(_searchController.text);
      }
    });
  }

  Future<void> _initSearchHistory() async {
    _searchHistory = await SearchHistoryService.init();
    if (mounted) {
      setState(() {
        _isHistoryLoading = false;
      });
    }
  }

  void _onScroll() {
    if (!_isLoading && 
        !_isLoadingMore &&  // Add this check
        _hasMorePages &&
        _searchResults != null &&
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 1200) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    if (_searchController.text.isNotEmpty || _lastQuery != null) {
      setState(() => _isLoadingMore = true);  // Set loading more state
      _currentPage++;
      _performSearch(
        _lastQuery ?? _searchController.text,
        isLoadingMore: true,
        useOriginalQuery: true,
      );
    }
  }

  Widget _buildLoadingState() {
    final localizations = AppLocalizations.of(context);
    return Center(  // Add this wrapper
      child: Padding(
        padding: const EdgeInsets.only(top: 80.0), // Changed from 120.0 to 80.0
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32.0), // Added vertical padding
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('searching'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Loading more...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

// Add helper method to detect set searches
bool _isSetSearch(String query) {
  // Check if query matches known set names
  final allSets = [
    ...searchCategories['vintage']!,
    ...searchCategories['modern']!,
  ];
  
  final normalizedQuery = query.toLowerCase().trim();
  return allSets.any((set) => 
    set['name']!.toLowerCase() == normalizedQuery ||
    query.startsWith('set.id:') ||
    query.startsWith('set:')
  );
}

// Add helper method to get set ID from name
String? _getSetIdFromName(String query) {
  final normalizedQuery = query.toLowerCase().trim();
  
  // Check all set categories
  final allSets = [
    ...searchCategories['vintage']!,
    ...searchCategories['modern']!,
  ];
  
  // Try exact match first
  final exactMatch = allSets.firstWhere(
    (set) => set['name']!.toLowerCase() == normalizedQuery,
    orElse: () => {'query': ''},
  );
  
  if (exactMatch['query']?.isNotEmpty ?? false) {
    return exactMatch['query'];
  }

  // Try contains match
  final containsMatch = allSets.firstWhere(
    (set) => set['name']!.toLowerCase().contains(normalizedQuery) ||
            normalizedQuery.contains(set['name']!.toLowerCase()),
    orElse: () => {'query': ''},
  );

  return containsMatch['query']?.isNotEmpty ?? false ? containsMatch['query'] : null;
}

// Update _buildSearchQuery method to handle raw number searches better
String _buildSearchQuery(String query) {
  // Clean the input query
  query = query.trim();
  
  // Check for exact set.id: prefix first
  if (query.startsWith('set.id:')) {
    return query;
  }

  // Try to match set name
  final setId = _getSetIdFromName(query);
  if (setId != null) {
    return setId;
  }

  // Handle number-only patterns first
  final numberPattern = RegExp(r'^(\d+)(?:/\d+)?$');
  final match = numberPattern.firstMatch(query);
  if (match != null) {
    final number = match.group(1)!;
    return 'number:"$number"';
  }

  // Handle name + number patterns
  final nameNumberPattern = RegExp(r'^(.*?)\s+(\d+)(?:/\d+)?$');
  final nameNumberMatch = nameNumberPattern.firstMatch(query);
  if (nameNumberMatch != null) {
    final name = nameNumberMatch.group(1)?.trim() ?? '';
    final number = nameNumberMatch.group(2)!;
    
    if (name.isNotEmpty) {
      return 'name:"$name" number:"$number"';
    } else {
      return 'number:"$number"';
    }
  }

  // Default to name search
  return query.contains(' ') 
    ? 'name:"$query"'
    : 'name:"*$query*"';
}

// Update _performSearch method to handle sort order correctly
Future<void> _performSearch(String query, {bool isLoadingMore = false, bool useOriginalQuery = false}) async {
  if (query.isEmpty) {
    setState(() {
      _searchResults = null;
      _showCategories = true;  // Show categories when search is cleared
    });
    return;
  }

  // Don't load more if we're already loading or there are no more pages
  if (isLoadingMore && (_isLoading || !_hasMorePages)) {
    return;
  }

  if (!isLoadingMore) {
    setState(() {
      _currentPage = 1;
      _searchResults = null;
      _showCategories = false;  // Hide categories when searching
    });
  }

  setState(() {
    if (!isLoadingMore) {
      _isLoading = true;
    }
  });

  try {
    if (!isLoadingMore) {
      _lastQuery = query; // Store query for pagination
      print('🔍 New search: "$query" (sort: $_currentSort)');
    }
    
    String searchQuery;
    if (useOriginalQuery) {
      searchQuery = query;
    } else {
      searchQuery = query.startsWith('set.id:') ? query : _buildSearchQuery(query.trim());
      
      // Only set default number sorting for new set searches if no explicit sort has been chosen
      if (searchQuery.startsWith('set.id:') && !isLoadingMore && 
          _currentSort == 'cardmarket.prices.averageSellPrice' && 
          !_sortAscending) {  // Only apply default if no sort is actively selected
        _currentSort = 'number';
        _sortAscending = true;
      }
    }

    print('Executing search with query: $searchQuery, sort: $_currentSort ${_sortAscending ? 'ASC' : 'DESC'}');
    
    // Make sure orderByDesc is correctly set based on _sortAscending
    final results = await _apiService.searchCards(
      query: searchQuery,
      page: _currentPage,
      pageSize: 30,
      orderBy: _currentSort,
      orderByDesc: !_sortAscending,  // This is correct, but let's add some debug logging
    );

    print('Search parameters:');
    print('- Query: $searchQuery');
    print('- Sort: $_currentSort');
    print('- Ascending: $_sortAscending');
    print('- OrderByDesc: ${!_sortAscending}');

    if (mounted) {
      List<dynamic> cardData = results['data'] as List? ?? [];
      final totalCount = results['totalCount'] as int? ?? 0;
      
      // If set search failed, try by name
      if (cardData.isEmpty && query.startsWith('set.id:')) {
        final setMap = searchCategories['modern']!
            .firstWhere((s) => s['query'] == query, orElse: () => {'name': ''});
        final setName = setMap['name'];
        
        if (setName?.isNotEmpty ?? false) {
          print('Retrying search with set name: $setName');
          final nameQuery = 'set:"$setName"';
          final nameResults = await _apiService.searchCards(
            query: nameQuery,
            page: _currentPage,
            pageSize: 30,
            orderBy: _currentSort,
            orderByDesc: !_sortAscending,
          );
          if (nameResults['data'] != null) {
            final List<dynamic> newCardData = nameResults['data'] as List;
            if (newCardData.isNotEmpty) {
              cardData = newCardData;
              final newTotalCount = (nameResults['totalCount'] as int?) ?? 0;
              print('Found $newTotalCount cards using set name');
              setState(() => _totalCards = newTotalCount);
            }
          }
        }
      }

      print('📊 Found $totalCount cards total');
      
      final newCards = cardData
          .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
          .toList();

      setState(() {
        if (isLoadingMore && _searchResults != null) {
          _searchResults = [..._searchResults!, ...newCards];
        } else {
          _searchResults = newCards;
          _totalCards = totalCount; // Only update total on initial search
        }
        
        _hasMorePages = (_currentPage * 30) < totalCount;
        _isLoading = false;
        _isLoadingMore = false;

        // Save to recent searches
        if (!isLoadingMore && _searchHistory != null && newCards.isNotEmpty) {
          _searchHistory!.addSearch(
            _formatSearchForDisplay(query), // Use formatted query
            imageUrl: newCards[0].imageUrl,
          );
        }
      });

      // Pre-load next page images
      if (_hasMorePages) {
        for (final card in newCards) {
          _loadImage(card.imageUrl);
        }
      }
    }
  } catch (e) {
    print('❌ Search error: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (!isLoadingMore) {
          _searchResults = [];
          _totalCards = 0;
        }
      });
      // Only show error for new searches, not pagination
      if (!isLoadingMore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Fix the _onSearchChanged method syntax
void _onSearchChanged(String query) {
  if (query.isEmpty) {
    setState(() {
      _searchResults = null;
      _setResults = null;
      _isInitialSearch = true;
      _showCategories = true;
    });
    return;
  }
  
  if (_searchDebounce?.isActive ?? false) {
    _searchDebounce!.cancel();
  }
  
  _searchDebounce = Timer(const Duration(milliseconds: 500), () {
    if (mounted && query == _searchController.text && query.isNotEmpty) {  // Fixed syntax here
      setState(() {
        _currentPage = 1;
        _isInitialSearch = true;
      });
      if (_searchMode == SearchMode.cards) {
        _performSearch(query);
      } else {
        _performSetSearch(query);
      }
    }
  });
}

  Future<void> _performQuickSearch(Map<String, dynamic> searchItem) async {
    setState(() {
      _searchController.text = searchItem['name'];
      _isLoading = true;
      _searchResults = null;
      _currentPage = 1;
      _hasMorePages = true;
      _showCategories = false;  // Hide categories when searching
      _lastQuery = searchItem['query'];  // Add this line
    });

    try {
      final query = searchItem['query'] as String;
      
      print('Executing quick search: $query');
      
      final results = await _apiService.searchCards(
        query: query,
        page: 1,
        pageSize: 30,
        orderBy: _currentSort,
        orderByDesc: !_sortAscending,
      );

      if (mounted) {
        final List<dynamic> cardData = results['data'] as List? ?? [];
        final totalCount = results['totalCount'] as int? ?? 0;
        
        final newCards = cardData
            .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
            .toList();

        setState(() {
          _searchResults = newCards;
          _totalCards = totalCount;
          _isLoading = false;
          _hasMorePages = (_currentPage * 30) < totalCount;
          _lastQuery = query;  // Store query for pagination
        });
      }
    } catch (e) {
      print('Quick search error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = [];
          _totalCards = 0;
        });
      }
    }
  }

// Update _buildQuickSearches method to use the new scroll indicator
Widget _buildSearchCategories() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildSearchSection('Vintage Sets', searchCategories['vintage']!, Icons.auto_awesome),
      _buildSearchSection('Latest Sets', searchCategories['modern']!, Icons.new_releases),
      _buildSearchSection('Sword & Shield', searchCategories['swsh']!, Icons.shield),
      _buildSearchSection('Sun & Moon', searchCategories['sm']!, Icons.wb_sunny),
      _buildSearchSection('XY Series', searchCategories['xy']!, Icons.flash_on),
      _buildSearchSection('Black & White', searchCategories['bw']!, Icons.brightness_2),
      _buildSearchSection('HeartGold SoulSilver', searchCategories['hgss']!, Icons.favorite),
      _buildSearchSection('Diamond & Pearl', searchCategories['dp']!, Icons.diamond),
      _buildSearchSection('EX Series', searchCategories['ex']!, Icons.extension),
      _buildSpecialSearches('Special Cards', searchCategories['special']!, Icons.stars),
      _buildSpecialSearches('Popular', searchCategories['popular']!, Icons.local_fire_department),
    ],
  );
}

Widget _buildSearchSection(String title, List<Map<String, dynamic>> items, IconData icon) {
  final colorScheme = Theme.of(context).colorScheme;
    
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 80, // Increased height for better logos
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildSetCard(items[index]),
        ),
      ),
    ],
  );
}

// Add new method for special/popular searches with text
Widget _buildSpecialSearches(String title, List<Map<String, dynamic>> items, IconData icon) {
  final colorScheme = Theme.of(context).colorScheme;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onBackground,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 48, // Smaller height for text-based items
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildSpecialSearchCard(items[index]),
        ),
      ),
    ],
  );
}

// Add method for special search card with text
Widget _buildSpecialSearchCard(Map<String, dynamic> item) {
  final colorScheme = Theme.of(context).colorScheme;
  
  return Card(
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    child: InkWell(
      onTap: () => _performQuickSearch(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item['icon'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              item['name'],
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Update the search card style
Widget _buildSearchCard(Map<String, dynamic> item) {
  final colorScheme = Theme.of(context).colorScheme;
  
  return Card(
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      onTap: () => _performQuickSearch(item),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceVariant.withOpacity(0.5),
              colorScheme.surface,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item['icon'],
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item['year'] != null || item['release'] != null)
                    Text(
                      item['year'] ?? item['release'] ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Update _buildRecentSearches to improve styling
Widget _buildRecentSearches() {
  final localizations = AppLocalizations.of(context);
  if (_isHistoryLoading || _searchHistory == null) {
    return const SizedBox.shrink();
  }

  final searches = _searchHistory!.getRecentSearches();
  if (searches.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  _searchHistory?.clearHistory();
                  setState(() {});
                },
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8), // Add vertical padding
            itemCount: searches.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 56,
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
            ),
            itemBuilder: (context, index) {
              final search = searches[index];
              return ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4), // Add vertical padding
                visualDensity: VisualDensity.compact,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 32,
                    height: 45,
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    child: search['imageUrl'] != null
                        ? Image.network(
                            search['imageUrl']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.search, size: 16),
                          )
                        : const Icon(Icons.search, size: 16),
                  ),
                ),
                title: Text(
                  search['query']!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  _searchController.text = search['query']!;
                  _performSearch(search['query']!);
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

// Add helper method to format search for display
String _formatSearchForDisplay(String query) {
  // Remove technical prefixes and format for display
  if (query.startsWith('set.id:')) {
    // Find matching set name from categories
    final allSets = [...searchCategories['vintage']!, ...searchCategories['modern']!];
    final matchingSet = allSets.firstWhere(
      (set) => set['query'] == query,
      orElse: () => {'name': query.replaceAll('set.id:', '')},
    );
    return matchingSet['name']!;
  }
  
  if (query.contains('subtypes:') || query.contains('rarity:')) {
    // Find matching special category
    final specials = searchCategories['special']!;
    final matchingSpecial = specials.firstWhere(
      (special) => special['query'] == query,
      orElse: () => {'name': query},
    );
    return matchingSpecial['name']!;
  }
  
  return query;
}

  Widget _buildShimmerItem() {
    return Container(
      decoration: CardStyles.cardDecoration(context),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceVariant,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    final localizations = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                localizations.translate('sortBy'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('done')),
              ),
            ),
            const Divider(height: 0),
            ListTile(
              title: const Text('Price (High to Low)'),
              leading: const Icon(Icons.attach_money),
              selected: _currentSort == 'cardmarket.prices.averageSellPrice' && !_sortAscending,
              onTap: () => _updateSort('cardmarket.prices.averageSellPrice', false),  // false for descending (high to low)
            ),
            ListTile(
              title: const Text('Price (Low to High)'),
              leading: const Icon(Icons.money_off),
              selected: _currentSort == 'cardmarket.prices.averageSellPrice' && _sortAscending,
              onTap: () => _updateSort('cardmarket.prices.averageSellPrice', true),  // true for ascending (low to high)
            ),
            ListTile(
              title: const Text('Name (A to Z)'),
              leading: const Icon(Icons.sort_by_alpha),
              selected: _currentSort == 'name' && _sortAscending,
              onTap: () => _updateSort('name', true),
            ),
            ListTile(
              title: const Text('Name (Z to A)'),
              leading: const Icon(Icons.sort_by_alpha),
              selected: _currentSort == 'name' && !_sortAscending,
              onTap: () => _updateSort('name', false),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Set Number (Low to High)'),
              leading: const Icon(Icons.format_list_numbered),
              selected: _currentSort == 'number' && _sortAscending,
              onTap: () => _updateSort('number', true),
            ),
            ListTile(
              title: const Text('Set Number (High to Low)'),
              leading: const Icon(Icons.format_list_numbered),
              selected: _currentSort == 'number' && !_sortAscending,
              onTap: () => _updateSort('number', false),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSort(String sortBy, bool ascending) {
    print('Updating sort:');
    print('- From: $_currentSort (ascending: $_sortAscending)');
    print('- To: $sortBy (ascending: $ascending)');

    setState(() {
      _currentSort = sortBy;
      _sortAscending = ascending;
      
      // Reset pagination when sorting changes
      _currentPage = 1;
      _searchResults = null;
      _hasMorePages = true;
    });
    
    Navigator.pop(context);

    // Rerun search with new sort
    if (_lastQuery != null) {
      print('Rerunning search with sort: $_currentSort (ascending: $_sortAscending)');
      _performSearch(_lastQuery!, useOriginalQuery: true);
    } else if (_searchController.text.isNotEmpty) {
      print('Running new search with sort: $_currentSort (ascending: $_sortAscending)');
      _performSearch(_searchController.text);
    }
  }

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

  Widget _buildNoResultsMessage() {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * LayoutConstants.emptyStatePaddingBottom,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('noCardsFound'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_currentSort.contains('cardmarket.prices'))
              Text(
                'Try removing price sorting as not all cards have prices',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              )
            else
              Text(
                localizations.translate('tryAdjustingSearch'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSetIcon(String setName) {
    // Look in all categories for the set icon
    for (final category in searchCategories.values) {
      final matchingSet = category.firstWhere(
        (set) => set['name'] == setName,
        orElse: () => {'icon': '📦'}, // Default icon if not found
      );
      if (matchingSet['name'] == setName) {
        return matchingSet['icon']!;
      }
    }
    return '📦'; // Default icon if not found in any category
  }

  // Add method to manage image loading
  Future<void> _loadImage(String url) async {
    // Skip if already loading or loaded
    if (_loadingRequestedUrls.contains(url) || _imageCache.containsKey(url)) {
      return;
    }

    _loadingRequestedUrls.add(url);

    if (_loadingImages.length >= _maxConcurrentLoads) {
      _loadQueue.add(url);
      return;
    }

    _loadingImages.add(url);
    try {
      print('Actually loading image: $url');
      final image = Image.network(
        url,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $url - $error');
          _loadingRequestedUrls.remove(url);
          // Return placeholder instead of error icon
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          );
        },
      );
      _imageCache[url] = image;
    } finally {
      _loadingImages.remove(url);
      if (_loadQueue.isNotEmpty) {
        final nextUrl = _loadQueue.removeAt(0);
        _loadImage(nextUrl);
      }
    }
  }

  // Update card grid item builder
  Widget _buildCardGridItem(TcgCard card) {
    final String url = card.imageUrl;
  
    if (!_loadingRequestedUrls.contains(url) && 
        !_imageCache.containsKey(url)) {
      // Delay image loading slightly to prevent too many concurrent requests
      Future.microtask(() => _loadImage(url));
    }

    final cachedImage = _imageCache[url];
    if (cachedImage != null) {
      return CardGridItem(
        key: ValueKey(card.id), // Add key for better list performance
        card: card,
        showQuickAdd: true,
        cached: cachedImage,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardDetailsScreen(
              card: card,
              heroContext: 'search',  // Add this line
            ),
          ),
        ),
      );
    }

    return CardGridItem(
      key: ValueKey(card.id),
      card: card,
      showQuickAdd: true,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailsScreen(
            card: card,
            heroContext: 'search',  // Add this line
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Theme(
        data: Theme.of(context).copyWith(
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              padding: MaterialStateProperty.all(EdgeInsets.zero),
              minimumSize: MaterialStateProperty.all(const Size(120, 36)), // Increased from 80 to 120
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                return Colors.transparent;
              }),
              // Remove showDefaultIndicator and use these properties instead
              side: MaterialStateProperty.all(BorderSide.none),
              shadowColor: MaterialStateProperty.all(Colors.transparent),
              surfaceTintColor: MaterialStateProperty.all(Colors.transparent),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
            ),
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 44, // Changed from 120 to 44 to match collections
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: AspectRatio(  // Add this to maintain aspect ratio
                aspectRatio: 1,
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pushNamed(context, '/scanner'),
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
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _searchMode == SearchMode.cards 
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
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: _clearSearch,
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
                  _getSortIcon(_currentSort),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: TcgApiService.sortOptions[_currentSort],
                onPressed: _showSortOptions,
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
                    selected: {_searchMode},
                    onSelectionChanged: (Set<SearchMode> modes) {
                      setState(() {
                        _searchMode = modes.first;
                        _searchResults = null;
                        _setResults = null;
                        _searchController.clear();
                        _showCategories = true;
                      });
                    },
                    segments: [
                      ButtonSegment(
                        value: SearchMode.cards,
                        label: Container(
                          height: double.infinity,
                          width: MediaQuery.of(context).size.width * 0.44, // Make buttons wider
                          decoration: BoxDecoration(
                            gradient: _searchMode == SearchMode.cards ? LinearGradient(
                              // ...existing gradient...
                              colors: isDark ? [
                                Colors.blue[900]!,
                                Colors.blue[800]!,
                              ] : [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ) : null,
                            borderRadius: BorderRadius.circular(18), // Increased from 8
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.style,
                                size: 16,
                                color: _searchMode == SearchMode.cards
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cards',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _searchMode == SearchMode.cards
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ButtonSegment(
                        value: SearchMode.sets,
                        label: Container(
                          height: double.infinity,
                          width: MediaQuery.of(context).size.width * 0.44, // Make buttons wider
                          decoration: BoxDecoration(
                            gradient: _searchMode == SearchMode.sets ? LinearGradient(
                              // ...existing gradient...
                              colors: isDark ? [
                                Colors.blue[900]!,
                                Colors.blue[800]!,
                              ] : [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ) : null,
                            borderRadius: BorderRadius.circular(18), // Increased from 8
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.collections_bookmark,
                                size: 16,
                                color: _searchMode == SearchMode.sets
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sets',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _searchMode == SearchMode.sets
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_searchResults == null && _setResults == null) ...[
          // Show categories and recent searches when no results
          SliverToBoxAdapter(
            child: _buildQuickSearchesHeader(),
          ),
          if (_showCategories)
            SliverToBoxAdapter(
              child: _buildSearchCategories(),
            ),
          SliverToBoxAdapter(
            child: _buildRecentSearches(),
          ),
        ] else ...[
          // Show search results
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Text(
                _searchMode == SearchMode.cards
                    ? 'Found $_totalCards cards'
                    : 'Found ${_setResults?.length ?? 0} sets',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: _searchMode == SearchMode.cards
                ? _buildCardResultsGrid()
                : _buildSetResultsGrid(),
          ),
        ],
      ],
    );
  }

  Widget _buildCardResultsGrid() {
    if (_searchResults == null || _searchResults!.isEmpty) {
      return SliverToBoxAdapter(child: _buildNoResultsMessage());
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _searchResults!.length,
          itemBuilder: (context, index) => _buildCardGridItem(_searchResults![index]),
        ),
        if (_hasMorePages && !_isLoading)
          _buildLoadingMoreIndicator(),
      ]),
    );
  }

  Widget _buildSetResultsGrid() {
    if (_setResults == null || _setResults!.isEmpty) {
      return SliverToBoxAdapter(child: _buildNoResultsMessage());
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildSetGridItem(_setResults![index]),
        childCount: _setResults!.length,
      ),
    );
  }

  // Add set search method
  Future<void> _performSetSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _setResults = null);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _apiService.searchSets(query: query);
      
      if (mounted) {
        setState(() {
          _setResults = results['data'] as List?;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Set search error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _setResults = null; // Fixed syntax error here
        });
      }
    }
  }

  // Add set results grid
  Widget _buildSetGrid() {
    if (_setResults == null) return const SizedBox.shrink();
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _setResults!.length,
      itemBuilder: (context, index) {
        final set = _setResults![index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              _searchController.text = set['name'];
              _searchMode = SearchMode.cards;
              _performSearch('set.id:${set['id']}'); // Changed to use _performSearch directly
            },
            child: Column(
              children: [
                if (set['images']?['logo'] != null)
                  Expanded(
                    child: Image.network(
                      set['images']['logo'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ListTile(
                  title: Text(
                    set['name'],
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    '${set['total']} cards • ${set['releaseDate']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickSearchesHeader() {
    return InkWell(
      onTap: () => setState(() => _showCategories = !_showCategories),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Text(
              'Quick Searches',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const Spacer(),
            Icon(
              _showCategories ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetGridItem(Map<String, dynamic> set) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _searchController.text = set['name'];
            _searchMode = SearchMode.cards;
            _performSearch('set.id:${set['id']}');
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (set['images']?['logo'] != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Image.network(
                    set['images']['logo'],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${set['total']} cards • ${set['releaseDate']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _setResults = null;
      _showCategories = true;
      _currentPage = 1;
      _hasMorePages = true;
      if (_currentSort != 'cardmarket.prices.averageSellPrice') {
        _currentSort = 'cardmarket.prices.averageSellPrice';
        _sortAscending = false;
      }
    });
  }

  Widget _buildSetCard(Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = item['query'] as String;
    final isSetQuery = query.startsWith('set.id:');
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _currentSort = 'number';
          _sortAscending = true;
          _performQuickSearch(item);
        },
        child: isSetQuery
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: Padding( // Add padding to make logos smaller
                padding: const EdgeInsets.all(16),
                child: Image.network(
                  _apiService.getSetLogo(query),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      item['icon'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  item['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
      ),
    );
  }
}

