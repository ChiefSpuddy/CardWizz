import 'package:flutter/material.dart';
import 'dart:async';
import '../services/tcg_api_service.dart';
import '../services/search_history_service.dart';
import '../screens/card_details_screen.dart';
import '../models/tcg_card.dart';
import '../widgets/card_grid_item.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _apiService = TcgApiService();
  final _searchController = TextEditingController();
  List<TcgCard>? _searchResults;
  bool _isLoading = false;
  String _currentSort = 'cardmarket.prices.averageSellPrice';
  bool _sortAscending = false;
  SearchHistoryService? _searchHistory;
  bool _isHistoryLoading = true;
  bool _isInitialSearch = true;

  // Add these constants at the top of the class
  static const quickSearches = [
    {'name': 'Rare Cards', 'icon': '⭐', 'description': 'Show rare cards only'},
    {'name': 'Full Art', 'icon': '🎨', 'description': 'Show full art cards'},
    {'name': 'Rainbow', 'icon': '🌈', 'description': 'Show rainbow rare cards'},
    {'name': 'Gold Cards', 'icon': '✨', 'description': 'Show gold rare cards'},
  ];

  static const recentSets = [
    {'name': 'Surging Sparks', 'icon': '⚡'},
    {'name': 'Prismatic Evolution', 'icon': '🌈'},
    {'name': 'Paradox Rift', 'icon': '🌀'},
    {'name': 'Paldea Evolved', 'icon': '🌟'},
    {'name': 'Crown Zenith', 'icon': '👑'},
    {'name': 'Silver Tempest', 'icon': '🌪'},
    {'name': 'Lost Origin', 'icon': '🌌'},
  ];

  static const popularSearches = [
    {'name': 'Charizard', 'icon': '🔥'},
    {'name': 'Pikachu', 'icon': '⚡'},
    {'name': 'Mew', 'icon': '✨'},
    {'name': 'Ex Cards', 'icon': '⭐'},
    {'name': 'VMAX', 'icon': '🌟'},
    {'name': 'Trainer Gallery', 'icon': '🎨'},
  ];

  // Add these fields after other declarations
  int _currentPage = 1;
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  int _totalCards = 0;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initSearchHistory();
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
        !_isInitialSearch &&
        _hasMorePages &&
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    if (_searchController.text.isNotEmpty) {
      _currentPage++;
      _performSearch(_searchController.text, isLoadingMore: true);
    }
  }

// Add this new method for a more stylish loading indicator
Widget _buildLoadingState() {
  return Center(  // Add this wrapper
    child: Padding(
      padding: const EdgeInsets.only(top: 120.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
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
                  'Searching...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

// Update _performSearch method
Future<void> _performSearch(String query, {bool isLoadingMore = false}) async {
  if (query.isEmpty) {
    setState(() => _searchResults = null);
    return;
  }

  if (!isLoadingMore) {
    _currentPage = 1;
    _hasMorePages = true;
  }

  if (!_hasMorePages) return;

  setState(() {
    _isLoading = true;
    if (!isLoadingMore) {
      _searchResults = null; // Set to null to show loading state
    }
  });

  try {
    print('Searching for: $query (page $_currentPage)'); // Updated debug print
    // Remove sorting for now to simplify the search
    final results = await _apiService.searchCards(
      query,
      page: _currentPage,
      pageSize: 30,
      sortBy: _currentSort,
      ascending: _sortAscending,
    );
    
    if (mounted) {
      final List<dynamic> cardData = results['data'] as List? ?? [];
      final totalCount = results['totalCount'] as int? ?? 0;
      
      final newCards = cardData
          .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
          .toList();

      setState(() {
        _totalCards = totalCount;
        _hasMorePages = _currentPage * 30 < totalCount;
        
        if (isLoadingMore && _searchResults != null) {
          _searchResults = [..._searchResults!, ...newCards];
        } else {
          _searchResults = newCards;
          _isInitialSearch = false;
        }
        _isLoading = false;
      });
      
      // Fixed nullable boolean check
      if (!isLoadingMore && _searchResults != null && _searchResults!.isNotEmpty) {
        _searchHistory?.addSearch(
          query,
          imageUrl: _searchResults![0].imageUrl,
        );
      }
    }
  } catch (e) {
    print('Search error: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!isLoadingMore) _searchResults = [];
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

// Update _buildMainContent method
Widget _buildMainContent() {
  return SingleChildScrollView(
    controller: _scrollController,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickSearches(),
        
        if (_searchResults == null && !_isLoading) ...[
          _buildRecentSearches(),
        ] else if (_isLoading && _searchResults == null) ...[
          _buildLoadingState(), // Show loading state
        ] else if (_searchResults != null) ...[
          // ... existing search results code ...
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),  // Added top padding
            child: Row(
              children: [
                Text(
                  'Search Results',
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
          if (_searchResults!.isEmpty && !_isLoading)
            _buildNoResultsMessage()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _searchResults!.length + (_isLoading ? 3 : 0),
                itemBuilder: (context, index) {
                  if (index >= _searchResults!.length) {
                    return _buildShimmerItem();
                  }
                  return CardGridItem(
                    card: _searchResults![index],
                    showQuickAdd: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailsScreen(
                          card: _searchResults![index],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ],
    ),
  );
}

// Fix the _onSearchChanged method
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
        _currentPage = 1;  // Reset page when searching
        _isInitialSearch = true;
      });
      _performSearch(query);
    }
  });
}

  Future<void> _performQuickSearch(String searchType) async {
    setState(() {
      _searchController.text = searchType;
      _isLoading = true;
      _searchResults = null;
      _currentPage = 1;
      _hasMorePages = true;
    });

    try {
      final customQuery = TcgApiService.popularSearchQueries[searchType] ?? 
                         TcgApiService.setSearchQueries[searchType];
      
      final results = await _apiService.searchCards(
        searchType,
        customQuery: customQuery,
        page: _currentPage,
        pageSize: 30,
        sortBy: _currentSort,
        ascending: _sortAscending,
      );
      
      if (mounted) {
        final List<dynamic> cardData = results['data'] as List? ?? [];
        final totalCount = results['totalCount'] as int? ?? 0;
        
        final newCards = cardData
            .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
            .toList();

        setState(() {
          _totalCards = totalCount;
          _hasMorePages = _currentPage * 30 < totalCount;
          _searchResults = newCards;
          _isLoading = false;
          _isInitialSearch = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _searchResults = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildQuickSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Popular Searches section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Popular Searches',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: popularSearches.length,
            itemBuilder: (context, index) {
              final search = popularSearches[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  avatar: Text(search['icon']!, style: const TextStyle(fontSize: 14)),
                  label: Text(search['name']!),
                  onPressed: () => _performQuickSearch(search['name']!),
                ),
              );
            },
          ),
        ),

        // Recent Sets section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Recent Sets',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: TcgApiService.setSearchQueries.length,
            itemBuilder: (context, index) {
              final setEntry = TcgApiService.setSearchQueries.entries.elementAt(index);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  avatar: Text(_getSetIcon(setEntry.key), style: const TextStyle(fontSize: 14)),
                  label: Text(setEntry.key),
                  onPressed: () => _performQuickSearch(setEntry.key),
                ),
              );
            },
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  String _getSetIcon(String setName) {
    switch (setName) {
      case 'Paldea Evolved':
        return '🌟';
      case 'Crown Zenith':
        return '👑';
      case 'Silver Tempest':
        return '🌪';
      case 'Lost Origin':
        return '🌌';
      case 'Scarlet & Violet':
        return '🔴';
      case 'Paradox Rift':
        return '🌀';
      case 'Surging Sparks':
        return '⚡'; // New icon
      case 'Prismatic Evolution':
        return '🌈'; // New icon
      default:
        return '📦';
    }
  }

  Widget _buildRecentSearches() {
    if (_isHistoryLoading || _searchHistory == null) {
      return const SizedBox.shrink();
    }

    final searches = _searchHistory!.getRecentSearches();
    if (searches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () {
                  _searchHistory?.clearHistory();
                  setState(() {});
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
        Column(
          children: searches.map((search) => ListTile(
            leading: search['imageUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      search['imageUrl']!,
                      width: 32,
                      height: 45,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.search),
            title: Text(search['query']!),
            onTap: () {
              _searchController.text = search['query']!;
              _performSearch(search['query']!);
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12, // Show 12 shimmer items
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceVariant,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceVariant,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
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
              selected: _currentSort == 'name' && !_sortAscending,
              onTap: () => _updateSort('name', false),
            ),
            ListTile(
              title: const Text('Name (Z to A)'),
              leading: const Icon(Icons.sort_by_alpha),
              selected: _currentSort == 'name' && _sortAscending,
              onTap: () => _updateSort('name', true),
            ),
            ListTile(
              title: const Text('Release Date (Newest)'),
              leading: const Icon(Icons.calendar_today),
              selected: _currentSort == 'set.releaseDate' && !_sortAscending,
              onTap: () => _updateSort('set.releaseDate', false),
            ),
            ListTile(
              title: const Text('Release Date (Oldest)'),
              leading: const Icon(Icons.calendar_today_outlined),
              selected: _currentSort == 'set.releaseDate' && _sortAscending,
              onTap: () => _updateSort('set.releaseDate', true),
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
    });
    Navigator.pop(context);
    if (_searchController.text.isNotEmpty) {
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No cards found',
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
                'Try adjusting your search terms',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove automatic leading widget
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search cards...',
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged, // Add this line
                textInputAction: TextInputAction.search,  // Add this to show search action on keyboard
              ),
            ),
          ],
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchResults = null);
              },
            ),
          IconButton(
            icon: Icon(_getSortIcon(_currentSort)),
            tooltip: TcgApiService.sortOptions[_currentSort],
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

