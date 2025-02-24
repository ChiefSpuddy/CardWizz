import 'package:flutter/material.dart';
import 'dart:async';
import '../services/tcg_api_service.dart';
import '../services/tcgdex_api_service.dart'; // Add this import
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
import '../constants/sets.dart';  // Add this import at the top
import '../constants/japanese_sets.dart';  // Add this import
import '../services/mtg_api_service.dart'; // Add this import
import '../constants/mtg_sets.dart'; // Add this import

// Move enum outside the class
enum SearchMode { eng, jpn, mtg }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  // Update the static method to always clear state
  static void clearSearchState(BuildContext context) {
    final state = context.findRootAncestorStateOfType<_SearchScreenState>();
    if (state != null) {
      state._clearSearch();
    }
  }

  static void startSearch(BuildContext context, String query) {
    // Find the search screen state
    final state = context.findRootAncestorStateOfType<_SearchScreenState>();
    if (state != null) {
      // Update the search controller and perform search
      state._searchController.text = query;
      state._performSearch(query);
    }
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _apiService = TcgApiService();
  final _tcgdexApi = TcgdexApiService(); // Add this line
  final _mtgApi = MtgApiService(); // Fixed variable name to match convention
  final _searchController = TextEditingController();
  List<TcgCard>? _searchResults;
  bool _isLoading = false;
  String _currentSort = 'cardmarket.prices.averageSellPrice';
  bool _sortAscending = false;
  SearchHistoryService? _searchHistory;
  bool _isHistoryLoading = true;
  bool _isInitialSearch = true;
  bool _showCategories = true; // Add this

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
  SearchMode _searchMode = SearchMode.eng;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get the current route
    final route = ModalRoute.of(context);
    
    // Check if this is a navigation triggered by bottom nav tap
    if (route?.isCurrent == true) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      final fromBottomNav = route?.isFirst == true || currentRoute == '/search';
      
      if (fromBottomNav) {
        _clearSearch();
      }
    }
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
            mainAxisSize: MainAxisSize.min,
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
List<Map<String, dynamic>> _getAllSets() {
  return [
    ...PokemonSets.getSetsForCategory('vintage'),
    ...PokemonSets.getSetsForCategory('modern'),
  ];
}

bool _isSetSearch(String query) {
  final allSets = _getAllSets();
  final normalizedQuery = query.toLowerCase().trim();
  return allSets.any((set) => 
    (set['name'] as String).toLowerCase() == normalizedQuery ||
    query.startsWith('set.id:') ||
    query.startsWith('set:')
  );
}

// Add helper method to get set ID from name
String? _getSetIdFromName(String query) {
  final normalizedQuery = query.toLowerCase().trim();
  final allSets = _getAllSets();
  
  // Try exact match first
  final exactMatch = allSets.firstWhere(
    (set) => (set['name'] as String).toLowerCase() == normalizedQuery,
    orElse: () => {'query': ''},
  );
  
  if ((exactMatch['query'] as String?)?.isNotEmpty ?? false) {
    return exactMatch['query'] as String;
  }

  // Try contains match
  final containsMatch = allSets.firstWhere(
    (set) => (set['name'] as String).toLowerCase().contains(normalizedQuery) ||
            normalizedQuery.contains((set['name'] as String).toLowerCase()),
    orElse: () => {'query': ''},
  );

  return (containsMatch['query'] as String?)?.isNotEmpty ?? false ? containsMatch['query'] as String : null;
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
  // Don't do anything if we've switched to MTG mode
  if (_searchMode == SearchMode.mtg) {
    _performMtgSearch(query);
    return;
  }

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
      _isLoading = true;  // Move this here to not affect _searchController.text state
      
      // Always set price sorting for set searches
      if (query.startsWith('set.id:')) {
        _currentSort = 'cardmarket.prices.averageSellPrice';
        _sortAscending = false;
      }
    });
  }

  try {
    if (!isLoadingMore) {
      _lastQuery = query; // Store query for pagination
      print('🔍 New search: "$query" (sort: $_currentSort)');
    }
    
    String searchQuery;
    if (useOriginalQuery) {
      searchQuery = query;
    } else {
      // Special handling for price queries
      if (query.contains('cardmarket.prices.averageSellPrice')) {
        searchQuery = query;  // Use raw query without modification
      } else {
        searchQuery = query.startsWith('set.id:') ? query : _buildSearchQuery(query.trim());
      }
      
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
      final List<dynamic> data = results['data'] as List? ?? [];  // Changed from cardData to data
      final totalCount = results['totalCount'] as int;
      
      // If set search failed, try by name
      if (data.isEmpty && query.startsWith('set.id:')) {
        final setMap = PokemonSets.getSetsForCategory('modern')
            .firstWhere((s) => s['query'] == query, orElse: () => {'name': ''});
        final String? setName = setMap['name'] as String?;
        
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
            data.clear();
            data.addAll(nameResults['data'] as List);
            final newTotalCount = (nameResults['totalCount'] as int?) ?? 0;
            print('Found $newTotalCount cards using set name');
            setState(() => _totalCards = newTotalCount);
          }
        }
      }

      print('📊 Found $totalCount cards total');
      
      final newCards = data
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

        // Don't clear searchController text when results load
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
      if (_searchMode == SearchMode.eng) {
        _performSearch(query);
      } else if (_searchMode == SearchMode.mtg) {
        _performMtgSearch(query);
      } else {
        _performSetSearch(query);
      }
    }
  });
}

// Add MTG search method
Future<void> _performMtgSearch(String query) async {
  if (query.isEmpty) {
    setState(() => _searchResults = null);
    return;
  }

  setState(() => _isLoading = true);

  try {
    final results = await _mtgApi.searchCards( // Changed from _mtgApiService to _mtgApi
      query: query,
      page: _currentPage,
      pageSize: 30,
      orderBy: _currentSort,
      orderByDesc: !_sortAscending,
    );

    if (mounted) {
      final List<dynamic> data = results['data'] as List? ?? [];
      final totalCount = results['totalCount'] as int;

      setState(() {
        _searchResults = data.map((card) => TcgCard.fromJson(card as Map<String, dynamic>)).toList();
        _totalCards = totalCount;
        _isLoading = false;
        _hasMorePages = (_currentPage * 30) < totalCount;
      });
    }
  } catch (e) {
    print('MTG search error: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
        _totalCards = 0;
      });
    }
  }
}

Future<void> _performQuickSearch(Map<String, dynamic> searchItem) async {
  setState(() {
    _searchController.text = searchItem['name'];
    _isLoading = true;
    _searchResults = null;
    _currentPage = 1;
    _hasMorePages = true;
    _showCategories = false;

    // Always sort by price high-to-low for set searches
    if (searchItem['query'].toString().startsWith('set.id:')) {
      _currentSort = 'cardmarket.prices.averageSellPrice';
      _sortAscending = false;
    }
  });

  try {
    // Special handling for Most Valuable search
    if (searchItem['isValueSearch'] == true) {
      setState(() {
        _currentSort = 'cardmarket.prices.averageSellPrice';
        _sortAscending = false;
      });
      
      // Use regular pagination with smaller page size
      final results = await _apiService.searchCards(
        query: searchItem['query'],
        orderBy: _currentSort,
        orderByDesc: true,
        pageSize: 30, // Standard page size
        page: _currentPage
      );
      
      if (mounted) {
        final List<dynamic> data = results['data'] as List? ?? [];
        final totalCount = results['totalCount'] as int;
        
        final newCards = data
            .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
            .where((card) => card.price != null && card.price! > 0)
            .toList();

        setState(() {
          _searchResults = newCards;
          _totalCards = totalCount;
          _isLoading = false;
          _hasMorePages = (_currentPage * 30) < totalCount;
          _lastQuery = searchItem['query'];
        });
      }
      return;
    }

    // Regular search for other items
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
      final cardData = results['data'] as List;
      final totalCount = results['totalCount'] as int;
      
      try {
        final newCards = cardData.map((card) => TcgCard.fromJson(card as Map<String, dynamic>)).toList();

        setState(() {
          _searchResults = newCards;
          _totalCards = totalCount;
          _isLoading = false;
          _hasMorePages = (_currentPage * 30) < totalCount;
          _lastQuery = query;
        });
      } catch (e) {
        print('Error parsing card data: $e');
        throw e;
      }
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
    // Define the eras based on search mode
    final sets = _searchMode == SearchMode.eng
      ? [
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
        ]
      : _searchMode == SearchMode.jpn
      ? [
          {'title': 'Latest Sets', 'sets': JapaneseSets.scarletViolet},
          {'title': 'Sword & Shield', 'sets': JapaneseSets.swordShield},
        ]
      : [
          {'title': 'Standard Sets', 'sets': MtgSets.standard},
          {'title': 'Modern Sets', 'sets': MtgSets.modern},
          {'title': 'Legacy Sets', 'sets': MtgSets.legacy},
        ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sets.length,
      itemBuilder: (context, index) {
        final era = sets[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                era['title'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: (era['sets'] as Map<String, Map<String, dynamic>>).length,
                itemBuilder: (context, index) {
                  final set = (era['sets'] as Map<String, Map<String, dynamic>>)
                      .entries.toList()[index];
                  return _buildSetCard({ // Changed from _buildSetLogoCard to _buildSetCard
                    'name': set.key,
                    'query': 'set.id:${set.value['code']}',
                    'icon': set.value['icon'],
                    'year': set.value['year'],
                  });
                },
              ),
            ),
          ],
        );
      },
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
    final allSets = _getAllSets();
    final matchingSet = allSets.firstWhere(
      (set) => set['query'] as String == query,
      orElse: () => {'name': query.replaceAll('set.id:', '')},
    );
    return matchingSet['name'] as String;
  }
  
  if (query.contains('subtypes:') || query.contains('rarity:')) {
    // Find matching special category
    final specials = PokemonSets.getSetsForCategory('special');
    final matchingSpecial = specials.firstWhere(
      (special) => special['query'] as String == query,
      orElse: () => {'name': query},
    );
    return matchingSpecial['name'] as String;
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
    // Don't apply Pokemon sorting to MTG cards
    if (_searchMode == SearchMode.mtg) {
      // MTG specific sorting
      setState(() {
        _currentSort = sortBy;
        _sortAscending = ascending;
        _currentPage = 1;
        _searchResults = null;
        _hasMorePages = true;
      });
      
      if (_lastQuery != null || _searchController.text.isNotEmpty) {
        _performMtgSearch(_lastQuery ?? _searchController.text);
      }
      return;
    }

    // Original Pokemon sorting logic
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
    // Look in all set lists for the set icon
    final allSets = [
      ...PokemonSets.scarletViolet.entries,
      ...PokemonSets.swordShield.entries,
      ...PokemonSets.sunMoon.entries,
      ...PokemonSets.xy.entries,
      ...PokemonSets.classic.entries,
      ...PokemonSets.ex.entries,
    ];
    
    final matchingSet = allSets.firstWhere(
      (entry) => entry.key == setName,
      orElse: () => MapEntry('', {'icon': '📦'}),
    );

    return matchingSet.value['icon'] as String? ?? '📦';
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 44,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leadingWidth: 72,
      leading: _searchResults != null || _setResults != null
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
                    onTap: () {
                      setState(() {
                        _searchResults = null;
                        _setResults = null;
                        _showCategories = true;
                        // Don't clear search text to allow easy return to results
                      });
                    },
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
                    onTap: _clearSearch,
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
              child: TextField( // Remove GestureDetector wrapper
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _searchMode == SearchMode.eng 
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
                onSubmitted: (value) => _performSearch(value), // Add this line
              ),
            ),
            if (_searchController.text.isNotEmpty || _searchResults != null) // Update this condition
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
                // Existing ENG segment
                ButtonSegment(
                  value: SearchMode.eng,
                  label: _buildSegmentLabel('🇺🇸', 'ENG'),
                ),
                // Existing JPN segment
                ButtonSegment(
                  value: SearchMode.jpn,
                  label: _buildSegmentLabel('🇯🇵', 'JPN'),
                ),
                // New MTG segment
                ButtonSegment(
                  value: SearchMode.mtg,
                  label: _buildSegmentLabel('✨', 'MTG'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for segment labels
  Widget _buildSegmentLabel(String emoji, String text) {
    return Container(
      height: double.infinity,
      width: MediaQuery.of(context).size.width * 0.28, // Adjusted width for 3 segments
      decoration: BoxDecoration(
        gradient: _searchMode.toString() == 'SearchMode.${text.toLowerCase()}' 
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
              color: _searchMode.toString() == 'SearchMode.${text.toLowerCase()}'
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Add isDark getter
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

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
          appBar: _buildAppBar(), // Use the new app bar builder
          body: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_searchMode == SearchMode.jpn && _setResults == null) {
      _loadJapaneseSets();
    }

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
                _searchMode == SearchMode.eng
                    ? 'Found $_totalCards cards'
                    : 'Found ${_setResults?.length ?? 0} sets',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: _searchMode == SearchMode.eng
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
      if (_searchMode == SearchMode.eng) {
        final results = await _apiService.searchSets(query: query);
        if (mounted) {
          setState(() {
            _setResults = results['data'] as List?;
            _isLoading = false;
          });
        }
      } else {
        // Use TCGdex API for Japanese sets
        final results = await _tcgdexApi.searchJapaneseSet(query);
        if (mounted) {
          setState(() {
            _setResults = results['data'] as List?;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Set search error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _setResults = null;
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
              _searchMode = SearchMode.eng;
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
          _searchController.text = set['name'];
          _performSetSearch(set['id']); // Use set ID directly
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (set['logo'] != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Image.network(
                    set['logo'],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image,
                      color: Theme.of(context).colorScheme.error,
                    ),
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

  static void clearSearchScreen(BuildContext context) {
    final state = context.findAncestorStateOfType<_SearchScreenState>();
    state?._clearSearch();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _setResults = null;
      _showCategories = true;
      _currentPage = 1;
      _hasMorePages = true;
      _lastQuery = null; // Clear the last query
      if (_currentSort != 'cardmarket.prices.averageSellPrice') {
        _currentSort = 'cardmarket.prices.averageSellPrice';
        _sortAscending = false;
      }
    });
  }

  Widget _buildSetCard(Map<String, dynamic> item, {bool showLabel = false}) {
  final colorScheme = Theme.of(context).colorScheme;
  final query = item['query'] as String;
  final isSetQuery = query.startsWith('set.id:');
  final setCode = isSetQuery ? query.replaceAll('set.id:', '') : '';
  final logoUrl = isSetQuery ? 'https://images.pokemontcg.io/$setCode/logo.png' : null;
  
  return Card(
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      onTap: () {
        if (isSetQuery) {
          setState(() {
            _currentSort = 'number';
            _sortAscending = true;
          });
        }
        _performQuickSearch(item);
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logoUrl != null)
              Expanded(
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    item['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  item['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            if (showLabel)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
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

void _loadJapaneseSets() async {
  if (_searchMode == SearchMode.jpn && _setResults == null) {
    setState(() => _isLoading = true);
    try {
      final results = await _tcgdexApi.getJapaneseSets();
      if (mounted) {
        setState(() {
          _setResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading Japanese sets: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

} // Add this closing brace for the _SearchScreenState class

