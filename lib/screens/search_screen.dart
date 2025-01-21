import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this
import '../services/tcg_api_service.dart';
import '../services/search_history_service.dart'; // Add this
import '../screens/card_details_screen.dart';
import '../models/tcg_card.dart';
import '../widgets/card_grid_item.dart';

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

  // Add these constants at the top of the class
  static const quickSearches = [
    {'name': 'Rare Cards', 'icon': '⭐', 'description': 'Show rare cards only'},
    {'name': 'Full Art', 'icon': '🎨', 'description': 'Show full art cards'},
    {'name': 'Rainbow', 'icon': '🌈', 'description': 'Show rainbow rare cards'},
    {'name': 'Gold Cards', 'icon': '✨', 'description': 'Show gold rare cards'},
  ];

  static const recentSets = [
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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_searchResults != null && _searchResults!.isNotEmpty) {
        _currentPage++;
        _performSearch(_searchController.text);
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = null;
    });

    try {
      final results = await _apiService.searchCards(
        query,
        sortBy: _currentSort,
        ascending: _sortAscending,
      );
      
      if (mounted) {
        // Save to history if search successful
        if (results['data'] is List && (results['data'] as List).isNotEmpty) {
          final firstCard = results['data'][0];
          await _searchHistory?.addSearch(
            query,
            imageUrl: firstCard['images']?['small'],
          );
        }
        
        setState(() {
          _searchResults = (results['data'] as List)
              .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
              .toList();
          _isLoading = false;
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

  Future<void> _performQuickSearch(String searchType) async {
    setState(() {
      _searchController.text = searchType;
      _isLoading = true;
      _searchResults = null;    // Fix: Remove extra parenthesis
    });

    try {
      final results = await _apiService.searchCards(
        searchType,
        customQuery: TcgApiService.popularSearchQueries[searchType] ?? 
                    TcgApiService.setSearchQueries[searchType],
      );
      
      if (mounted) {
        setState(() {
          _searchResults = (results['data'] as List)
              .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
              .toList();
          _isLoading = false;
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold)),
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: searches.length,
          itemBuilder: (context, index) {
            final search = searches[index];
            return ListTile(
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
              onTap: () => _performSearch(search['query']!),
            );
          },
        ),
      ],
    );
  }

  // Modify the _buildMainContent method
  Widget _buildMainContent() {
    if (_searchResults != null) {
      return _isLoading && _currentPage == 1
          ? const Center(child: CircularProgressIndicator())
          : _searchResults!.isEmpty
              ? const Center(child: Text('No cards found'))
              : _buildResults();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildQuickSearches(),
          _buildRecentSearches(),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) => CardGridItem(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search cards...',
            border: InputBorder.none,
          ),
          onSubmitted: _performSearch,
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
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

