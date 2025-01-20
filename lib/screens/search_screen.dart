import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tcg_api_service.dart';
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
      final results = await _apiService.searchCards(query);
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

  Future<void> _performQuickSearch(String searchType) async {
    setState(() {
      _searchController.text = searchType;
      _isLoading = true;
      _searchResults = null;
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
      default:
        return '📦';
    }
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

    return Column(
      children: [
        _buildQuickSearches(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : const Center(child: Text('Search for Pokémon cards')),
        ),
      ],
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
        ],
      ),
      body: _buildMainContent(), // This is the key change
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

