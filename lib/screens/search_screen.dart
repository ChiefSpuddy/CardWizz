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
      {'name': 'Team Rocket', 'icon': '🚀', 'year': '2000', 'query': 'set.id:base5', 'description': 'Evil team themed set'},
      {'name': 'Gym Heroes', 'icon': '🏃', 'year': '2000', 'query': 'set.id:gym1', 'description': 'Gym Leader cards'},
      {'name': 'Gym Challenge', 'icon': '🏆', 'year': '2000', 'query': 'set.id:gym2', 'description': 'Gym Leader cards'},
      {'name': 'Neo Genesis', 'icon': '✨', 'year': '2000', 'query': 'set.id:neo1', 'description': 'First Neo series set'},
      {'name': 'Neo Discovery', 'icon': '🔍', 'year': '2001', 'query': 'set.id:neo2', 'description': 'Neo Discovery set'},
      {'name': 'Neo Revelation', 'icon': '📜', 'year': '2001', 'query': 'set.id:neo3', 'description': 'Neo Revelation set'},
      {'name': 'Neo Destiny', 'icon': '⭐', 'year': '2002', 'query': 'set.id:neo4', 'description': 'Neo Destiny set'},
    ],
    'modern': [
      {'name': 'Prismatic Evolution', 'icon': '💎', 'release': '2024', 'query': 'set.id:sv8pt5', 'description': 'Latest expansion'},
      {'name': 'Surging Sparks', 'icon': '⚡', 'release': '2024', 'query': 'set.id:sv8', 'description': 'Electric themed set'},
      {'name': '151', 'icon': '🌟', 'release': '2023', 'query': 'set.id:sv3pt5', 'description': 'Original 151 Pokemon'},
      {'name': 'Temporal Forces', 'icon': '⌛', 'release': '2024', 'query': 'set.id:sv5', 'description': 'Time themed set'},
      {'name': 'Paradox Rift', 'icon': '🌀', 'release': '2023', 'query': 'set.id:sv4', 'description': 'Paradox Pokemon'},
      {'name': 'Obsidian Flames', 'icon': '🔥', 'release': '2023', 'query': 'set.id:sv3', 'description': 'Fire themed set'},
      {'name': 'Paldea Evolved', 'icon': '🌟', 'release': '2023', 'query': 'set.id:sv2', 'description': 'Paldean Pokemon'},
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
      _hasMorePages &&
      _searchResults != null &&
      _scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 1200) {
    _loadNextPage();
  }
  }

  void _loadNextPage() {
    if (_searchController.text.isNotEmpty || _lastQuery != null) {
      _currentPage++;
      // Pass the original query without modification
      _performSearch(_lastQuery ?? _searchController.text, isLoadingMore: true, useOriginalQuery: true);
    }
  }

// Add this new method for a more stylish loading indicator
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

// Update _performSearch debug logging
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

  setState(() => _isLoading = true);

  try {
    if (!isLoadingMore) {
      _lastQuery = query; // Store query for pagination
      print('🔍 New search: "$query" (sort: $_currentSort)');
    }
    
    String searchQuery;
    if (useOriginalQuery) {
      // Use the query as-is for pagination
      searchQuery = query;
    } else {
      // Only build search query for new searches
      searchQuery = query.startsWith('set.id:') ? query : _buildSearchQuery(query.trim());
      
      // Set default sorting for set searches
      if (searchQuery.startsWith('set.id:') && !isLoadingMore) {
        _currentSort = 'number';
        _sortAscending = true;
      }
    }

    print('Executing search with query: $searchQuery, page: $_currentPage');
    
    final results = await _apiService.searchCards(
      query: searchQuery,
      page: _currentPage,
      pageSize: 30,
      orderBy: _currentSort,
      orderByDesc: !_sortAscending,
    );
    
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
            query,
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

// Add helper method for search query building
String _buildSearchQuery(String query) {
  // Check for number pattern (e.g., "pikachu 4", "4/123", "4")
  final numberMatch = RegExp(r'(\d+)(?:/\d+)?$').firstMatch(query);
  
  if (numberMatch != null) {
    final number = numberMatch.group(1)!;
    final name = query.substring(0, numberMatch.start).trim();
    
    if (name.isNotEmpty) {
      return 'name:"$name" number:"$number"';
    } else {
      return 'number:"$number"';
    }
  }
  
  // For non-number searches, use contains
  return 'name:"*$query*"';
}

// Fix the _onSearchChanged method syntax
void _onSearchChanged(String query) {
  if (query.isEmpty) {
    setState(() {
      _searchResults = null;
      _isInitialSearch = true;
    });
    return;
  }
  
  if (_searchDebounce?.isActive ?? false) {
    _searchDebounce!.cancel();
  }
  
  _searchDebounce = Timer(const Duration(milliseconds: 500), () {
    if (mounted && query == _searchController.text && query.isNotEmpty) {
      setState(() {
        _currentPage = 1;
        _isInitialSearch = true;
      });
      _performSearch(query);
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
    });

    try {
      // Add retry logic and better query handling
      String query = searchItem['query'] ?? '';
      
      // Always use original query for pagination
      final originalQuery = query;
      
      // For set searches, use number sorting
      if (query.startsWith('set.id:')) {
        _currentSort = 'number';
        _sortAscending = true;
      } else if (query.contains('rarity:')) {
        _currentSort = 'cardmarket.prices.averageSellPrice';
        _sortAscending = false;
      }

      print('Executing search with query: $query, sort: $_currentSort ${_sortAscending ? 'ASC' : 'DESC'}');

      int retryCount = 0;
      Map<String, dynamic> results;

      do {
        results = await _apiService.searchCards(
          query: query,
          page: _currentPage,
          pageSize: 30,
          orderBy: _currentSort,
          orderByDesc: !_sortAscending,
        );

        if ((results['data'] as List).isNotEmpty || retryCount >= 2) break;
        
        // If no results, try alternative query
        if (query.startsWith('set.id:')) {
          query = 'set:"${searchItem['name']}"';
          print('Retrying with alternative query: $query');
        }
        
        retryCount++;
      } while (retryCount < 3);

      if (mounted) {
        final List<dynamic> cardData = results['data'] as List? ?? [];
        final totalCount = results['totalCount'] as int? ?? 0;
        
        if (cardData.isEmpty) {
          print('No results found for query: $query');
        } else {
          print('Found ${cardData.length} cards for query: $query');
        }

        final newCards = cardData
            .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
            .toList();

        setState(() {
          _totalCards = totalCount;
          _hasMorePages = _currentPage * 30 < totalCount;
          _searchResults = newCards;
          _isLoading = false;
          _isInitialSearch = false;
          // Store original query for pagination
          _lastQuery = originalQuery;
        });
      }
    } catch (e) {
      print('Search error with query: ${searchItem['query']} - Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      _buildSearchSection('Special Cards', searchCategories['special']!, Icons.stars),
      _buildSearchSection('Popular', searchCategories['popular']!, Icons.local_fire_department),
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
        height: 64,  // Even more compact
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildSearchCard(items[index]),
        ),
      ),
    ],
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
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32), // Added vertical padding
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: searches.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 56,
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
            ),
            itemBuilder: (context, index) {
              final search = searches[index];
              return ListTile(
                contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                visualDensity: VisualDensity.compact,
                leading: Container(
                  width: 32,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: search['imageUrl'] != null
                      ? Image.network(
                          search['imageUrl']!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.search, size: 16),
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
              onTap: () => _updateSort('cardmarket.prices.averageSellPrice', false),
            ),
            ListTile(
              title: const Text('Price (Low to High)'),
              leading: const Icon(Icons.money_off),
              selected: _currentSort == 'cardmarket.prices.averageSellPrice' && _sortAscending,
              onTap: () => _updateSort('cardmarket.prices.averageSellPrice', true),
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
          ],
        ),
      ),
    );
  }

  void _updateSort(String sortBy, bool ascending) {
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
      _performSearch(_lastQuery!, useOriginalQuery: true);
    } else if (_searchController.text.isNotEmpty) {
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Theme(
        data: Theme.of(context).copyWith(
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 56, // Reduced height
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  onPressed: () => Navigator.pushNamed(context, '/scanner'),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                        hintText: AppLocalizations.of(context).translate('searchCards'),
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
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = null);
                      },
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
          ),
          body: _buildMainContent(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _imageCache.clear();
    _loadQueue.clear();
    _loadingImages.clear();
    _loadingRequestedUrls.clear();
    super.dispose();
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Categories toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // Added bottom padding
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
                IconButton(
                  icon: Icon(
                    _showCategories ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showCategories = !_showCategories),
                ),
              ],
            ),
          ),
        ),

        // Categories section (collapsible)
        if (_showCategories)
          SliverToBoxAdapter(
            child: _buildSearchCategories(),
          ),

        // Recent searches or loading state
        if (_searchResults == null) 
          SliverToBoxAdapter(
            child: _isLoading 
              ? _buildLoadingState()
              : _buildRecentSearches(),
          ),

        // Search results header
        if (_searchResults != null) 
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'Found $_totalCards cards',  // Updated text
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_isLoading) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // Search results grid - updated with better null checking
        if (_searchResults != null && _searchResults!.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _searchResults!.length) {
                    if (_hasMorePages) {
                      return _buildShimmerItem();
                    }
                    return null; // Return null to prevent extra items
                  }
                  return _buildCardGridItem(_searchResults![index]);
                },
                childCount: _searchResults!.length + (_hasMorePages ? 3 : 0),
              ),
            ),
          ),

        // Add loading indicator at bottom when loading more
        if (_isLoading && _searchResults != null && _searchResults!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(height: 8),
                  Text(
                    'Loading more cards...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ...rest of existing content...
      ],
    );
  }
}

