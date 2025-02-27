import 'package:flutter/material.dart';
import 'dart:async';
import '../services/tcg_api_service.dart';
import '../services/tcgdex_api_service.dart';
import '../services/search_history_service.dart';
import '../services/mtg_api_service.dart';
import '../models/tcg_card.dart';
import '../constants/sets.dart';
import '../constants/japanese_sets.dart';
import '../constants/mtg_sets.dart';
import '../utils/image_utils.dart';
import 'card_details_screen.dart';

// Import our extracted components
import '../widgets/search/search_app_bar.dart';
import '../widgets/search/search_categories.dart';
import '../widgets/search/search_categories_header.dart';
import '../widgets/search/recent_searches.dart';
import '../widgets/search/loading_state.dart';
import '../widgets/search/loading_indicators.dart';
import '../widgets/search/card_grid.dart';
import '../widgets/search/set_grid.dart';
import '../widgets/styled_toast.dart';  // Add this import
import 'dart:math' as math;
import '../widgets/search/card_grid_item.dart';  // Add this import

// Move enum outside the class
enum SearchMode { eng, jpn, mtg }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  // Static methods for external interaction
  static void clearSearchState(BuildContext context) {
    final state = context.findRootAncestorStateOfType<_SearchScreenState>();
    if (state != null) {
      state._clearSearch();
    }
  }

  static void startSearch(BuildContext context, String query) {
    final state = context.findRootAncestorStateOfType<_SearchScreenState>();
    if (state != null) {
      state._searchController.text = query;
      state._performSearch(query);
    }
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _apiService = TcgApiService();
  final _tcgdexApi = TcgdexApiService();
  final _mtgApi = MtgApiService();
  final _searchController = TextEditingController();
  List<TcgCard>? _searchResults;
  bool _isLoading = false;
  String _currentSort = 'cardmarket.prices.averageSellPrice';
  bool _sortAscending = false;
  SearchHistoryService? _searchHistory;
  bool _isHistoryLoading = true;
  bool _isInitialSearch = true;
  bool _showCategories = true;

  // Pagination fields
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  int _totalCards = 0;
  bool _hasMorePages = true;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  // Image cache manager
  static const _maxConcurrentLoads = 3;
  final _loadingImages = <String>{};
  final _imageCache = <String, Image>{};
  final _loadQueue = <String>[];
  final Set<String> _loadingRequestedUrls = {};

  // Search state
  String? _lastQuery;
  SearchMode _searchMode = SearchMode.eng;
  List<dynamic>? _setResults;

  // Add these new fields near the top of the class
  bool _wasSearchActive = false;
  String? _lastActiveSearch;

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
    
    // Handle navigation events
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      final fromBottomNav = route?.isFirst == true || currentRoute == '/search';
      
      // Only clear if coming from bottom nav and no previous search
      if (fromBottomNav && !_wasSearchActive) {
        _clearSearch();
      } else if (_wasSearchActive && _lastActiveSearch != null) {
        // Don't clear results when returning from card details
        if (_searchResults == null || _searchResults!.isEmpty) {
          _searchController.text = _lastActiveSearch!;
          _performSearch(_lastActiveSearch!, useOriginalQuery: true);
        }
        _wasSearchActive = false;
        _lastActiveSearch = null;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initSearchHistory() async {
    try {
      _searchHistory = await SearchHistoryService.init();
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
      // Immediately load saved searches
      if (mounted && _searchHistory != null) {
        setState(() {}); // Trigger rebuild to show recent searches
      }
    } catch (e) {
      print('Error initializing search history: $e');
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_isLoading && 
        !_isLoadingMore &&
        _hasMorePages &&
        _searchResults != null &&
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 1200) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    if (_isLoading || _isLoadingMore || !_hasMorePages) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;
    
    // Use the correct search method based on the mode
    if (_searchMode == SearchMode.mtg) {
      _performMtgSearch(_lastQuery ?? _searchController.text);
    } else {
      _performSearch(
        _lastQuery ?? _searchController.text,
        isLoadingMore: true,
        useOriginalQuery: true,
      );
    }
  }

  // Helpers for API search queries
  List<Map<String, dynamic>> _getAllSets() {
    if (_searchMode == SearchMode.eng) {
      return [
        ...PokemonSets.getSetsForCategory('vintage'),
        ...PokemonSets.getSetsForCategory('modern'),
      ];
    } else if (_searchMode == SearchMode.mtg) {
      return _getAllMtgSets();
    }
    return [];
  }

  List<Map<String, dynamic>> _getAllMtgSets() {
    return [
      ...MtgSets.getSetsForCategory('standard'),
      ...MtgSets.getSetsForCategory('commander'),
      ...MtgSets.getSetsForCategory('special'),
      ...MtgSets.getSetsForCategory('modern'),
      ...MtgSets.getSetsForCategory('pioneer'),
      ...MtgSets.getSetsForCategory('legacy'),
      ...MtgSets.getSetsForCategory('classic'),
    ];
  }

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

  Future<void> _performSearch(String query, {bool isLoadingMore = false, bool useOriginalQuery = false}) async {
    // Handle MTG mode separately
    if (_searchMode == SearchMode.mtg) {
      _performMtgSearch(query);
      return;
    }

    // Handle Japanese set mode separately
    if (_searchMode == SearchMode.jpn) {
      _performSetSearch(query);
      return;
    }

    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _showCategories = true;
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
        _showCategories = false;
        _isLoading = true;
        
        // Set price sorting for set searches
        if (query.startsWith('set.id:')) {
          _currentSort = 'cardmarket.prices.averageSellPrice';
          _sortAscending = false;
        }
      });
    }

    try {
      if (!isLoadingMore) {
        _lastQuery = query;
      }
      
      String searchQuery;
      if (useOriginalQuery) {
        searchQuery = query;
      } else {
        // Special handling for price queries
        if (query.contains('cardmarket.prices.averageSellPrice')) {
          searchQuery = query;
        } else {
          searchQuery = query.startsWith('set.id:') ? query : _buildSearchQuery(query.trim());
        }
        
        // Default number sorting for new set searches
        if (searchQuery.startsWith('set.id:') && !isLoadingMore && 
            _currentSort == 'cardmarket.prices.averageSellPrice' && 
            !_sortAscending) {
          _currentSort = 'number';
          _sortAscending = true;
        }
      }
      
      // Execute the search
      final results = await _apiService.searchCards(
        query: searchQuery,
        page: _currentPage,
        pageSize: 30,
        orderBy: _currentSort,
        orderByDesc: !_sortAscending,
      );

      if (mounted) {
        final List<dynamic> data = results['data'] as List? ?? [];
        final totalCount = results['totalCount'] as int;
        
        // Try by set name if set.id search fails
        if (data.isEmpty && query.startsWith('set.id:')) {
          final setMap = PokemonSets.getSetsForCategory('modern')
              .firstWhere((s) => s['query'] == query, orElse: () => {'name': ''});
          final String? setName = setMap['name'] as String?;
          
          if (setName?.isNotEmpty ?? false) {
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
              setState(() => _totalCards = newTotalCount);
            }
          }
        }
        
        final newCards = data
            .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
            .toList();

        setState(() {
          if (isLoadingMore && _searchResults != null) {
            _searchResults = [..._searchResults!, ...newCards];
          } else {
            _searchResults = newCards;
            _totalCards = totalCount;
          }
          
          _hasMorePages = (_currentPage * 30) < totalCount;
          _isLoading = false;
          _isLoadingMore = false;

          // Save to search history with more details
          if (!isLoadingMore && _searchHistory != null && newCards.isNotEmpty) {
            final isSetSearch = query.startsWith('set.id:');
            _searchHistory!.addSearch(
              isSetSearch ? _formatSearchForDisplay(query) : query,
              imageUrl: newCards[0].imageUrl,
              isSetSearch: isSetSearch,
              cardId: isSetSearch ? null : newCards[0].id, // Save card ID for direct navigation
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

        if (!isLoadingMore) {
          // Show styled toast from bottom
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StyledToast(
                    title: 'Search Failed',
                    subtitle: 'Please try a different search term',
                    icon: Icons.error_outline,
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
            ),
          );
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    }
  }

  Future<void> _performMtgSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _showCategories = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = null;
      _setResults = null;
      _showCategories = false;
    });

    try {
      // Always enforce price high-to-low for ALL MTG searches
      _currentSort = 'cardmarket.prices.averageSellPrice';
      _sortAscending = false;
      
      // Format query for Scryfall API
      String searchQuery = query;
      String originalSetCode = "";
      
      if (query.startsWith('set.id:')) {
        originalSetCode = query.substring(7).trim();
        searchQuery = 'e:$originalSetCode';
        print('MTG search for set: "$originalSetCode" using query: "$searchQuery" (sorted by price high-to-low)');
      } else {
        print('MTG general search: "$searchQuery" (sorted by price high-to-low)');
      }

      final results = await _mtgApi.searchCards(
        query: searchQuery,
        page: _currentPage,
        pageSize: 30,
        orderBy: _currentSort,        // Already set to price
        orderByDesc: !_sortAscending, // Already set to descending (high to low)
      );

      if (mounted) {
        final List<dynamic> cardsData = results['data'] as List? ?? [];
        final int totalCount = results['totalCount'] as int;
        final bool hasMore = results['hasMore'] ?? false;
        
        print('MTG API returned ${cardsData.length} cards, total: $totalCount, hasMore: $hasMore');
        
        if (cardsData.isEmpty) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _searchResults = [];
            _totalCards = 0;
            _hasMorePages = false;
          });
          return;
        }
        
        // Convert to TcgCard objects
        final cards = cardsData.map((data) {
          return TcgCard(
            id: data['id'] as String? ?? '',
            name: data['name'] as String? ?? 'Unknown Card',
            imageUrl: data['imageUrl'] as String? ?? '',
            largeImageUrl: data['largeImageUrl'] as String? ?? '',
            number: data['number'] as String? ?? '',
            rarity: data['rarity'] as String? ?? '',
            price: data['price'] as double? ?? 0.0,
            set: TcgSet(
              id: data['set']['id'] as String? ?? '',
              name: data['set']['name'] as String? ?? '',
            ),
          );
        }).toList();
        
        setState(() {
          if (_isLoadingMore && _searchResults != null) {
            _searchResults = [..._searchResults!, ...cards];
          } else {
            _searchResults = cards;
          }
          _totalCards = totalCount;
          _isLoading = false;
          _isLoadingMore = false;
          _hasMorePages = hasMore;
        });
        
        // Debug log the first few cards
        if (cards.isNotEmpty) {
          for (int i = 0; i < math.min(3, cards.length); i++) {
            print('Card $i: ${cards[i].name} - ${cards[i].imageUrl}');
          }
        }
        
        // Save to search history with the correct display name
        if (_searchHistory != null && cards.isNotEmpty) {
          String displayName;
          
          if (query.startsWith('set.id:')) {
            // Try to get a nice set name from our constants
            displayName = _getSetNameFromCode(originalSetCode) ?? 
                         'MTG: ${originalSetCode.toUpperCase()}';
          } else {
            displayName = query;
          }
          
          _searchHistory!.addSearch(
            displayName,
            imageUrl: cards.isNotEmpty ? cards[0].imageUrl : null,
            isSetSearch: query.startsWith('set.id:'),
          );
        }
      }
    } catch (e, stack) {
      print('MTG search error: $e');
      print('Stack trace: $stack');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _searchResults = [];
          _totalCards = 0;
          _hasMorePages = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MTG search failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Add this helper method to get a set name from code
  String? _getSetNameFromCode(String code) {
    // Clean the code
    final cleanCode = code.trim().toLowerCase();
    
    // Try to find the set in all MTG sets
    final mtgSets = _getAllMtgSets();
    
    final matchingSet = mtgSets.firstWhere(
      (set) => set['code'].toString().toLowerCase() == cleanCode,
      orElse: () => {'name': null},
    );
    
    return matchingSet['name'] as String?;
  }

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
      } else if (_searchMode == SearchMode.jpn) {
        // Use TCGdex API for Japanese sets
        final results = await _tcgdexApi.searchJapaneseSet(query);
        if (mounted) {
          setState(() {
            _setResults = results['data'] as List?;
            _isLoading = false;
          });
        }
      } else if (_searchMode == SearchMode.mtg) {
        try {
          final response = await _mtgApi.getSetDetails(query);
          if (mounted) {
            if (response != null) {
              // Format the response to match our expected structure
              final formattedSets = [response];
              setState(() {
                _setResults = formattedSets;
                _isLoading = false;
              });
            } else {
              setState(() {
                _setResults = [];
                _isLoading = false;
              });
            }
          }
        } catch (e) {
          print('Error fetching MTG set details: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _setResults = [];
            });
          }
        }
      }
    } catch (e) {
      print('Set search error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _setResults = [];
        });
      }
    }
  }

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

  Future<void> _performQuickSearch(Map<String, dynamic> searchItem) async {
    setState(() {
      _searchController.text = searchItem['name'];
      _isLoading = true;
      _searchResults = null;
      _currentPage = 1;
      _hasMorePages = true;
      _showCategories = false;

      // Sort by price high-to-low for set searches (both Pokemon and MTG)
      if (searchItem['query'].toString().startsWith('set.id:')) {
        _currentSort = 'cardmarket.prices.averageSellPrice';
        _sortAscending = false;
      }
    });

    try {
      // Check if this is an MTG search
      if (_searchMode == SearchMode.mtg) {
        // Set price sorting for MTG searches
        _currentSort = 'cardmarket.prices.averageSellPrice';
        _sortAscending = false;
        
        // Use MTG search directly
        final query = searchItem['query'] as String;
        await _performMtgSearch(query);
        return;
      }

      // Rest of the existing code for Pokemon searches
      // Special handling for Most Valuable search
      if (searchItem['isValueSearch'] == true) {
        setState(() {
          _currentSort = 'cardmarket.prices.averageSellPrice';
          _sortAscending = false;
        });
        
        final results = await _apiService.searchCards(
          query: searchItem['query'],
          orderBy: _currentSort,
          orderByDesc: true,
          pageSize: 30,
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
        
        final newCards = cardData
            .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
            .toList();

        setState(() {
          _searchResults = newCards;
          _totalCards = totalCount;
          _isLoading = false;
          _hasMorePages = (_currentPage * 30) < totalCount;
          _lastQuery = query;
        });

        // Add to search history after successful search
        _addToSearchHistory(
          searchItem['name'],
          imageUrl: newCards.isNotEmpty ? newCards[0].imageUrl : null,
        );
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

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // For MTG searches, show that high-to-low is the default and always applied
        bool isMtgMode = _searchMode == SearchMode.mtg;
        
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Sort By',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done'),
                ),
              ),
              if (isMtgMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'MTG cards are always sorted by price (high to low)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const Divider(height: 16),
              
              ListTile(
                title: const Text('Price (High to Low)'),
                leading: const Icon(Icons.attach_money),
                selected: _currentSort == 'cardmarket.prices.averageSellPrice' && !_sortAscending,
                // For MTG mode, disable other sorting options
                enabled: !isMtgMode || (_currentSort == 'cardmarket.prices.averageSellPrice' && !_sortAscending),
                onTap: () => _updateSort('cardmarket.prices.averageSellPrice', false),
              ),
              
              // Only show other options if not in MTG mode
              if (!isMtgMode) ...[
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
            ],
          ),
        );
      },
    );
  }

  void _updateSort(String sortBy, bool ascending) {
    // For MTG mode, always override to price high-to-low
    if (_searchMode == SearchMode.mtg) {
      sortBy = 'cardmarket.prices.averageSellPrice';
      ascending = false;
    }
    
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

  String _formatSearchForDisplay(String query) {
    // Format for display in search history
    if (query.startsWith('set.id:')) {
      // Find matching set name
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
  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _setResults = null;
      _showCategories = true;
      _currentPage = 1;
      _hasMorePages = true;
      _lastQuery = null;
      if (_currentSort != 'cardmarket.prices.averageSellPrice') {
        _currentSort = 'cardmarket.prices.averageSellPrice';
        _sortAscending = false;
      }
    });
  }

  // Image loading
  Future<void> _loadImage(String url) async {
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
      final image = Image.network(
        url,
        errorBuilder: (context, error, stackTrace) {
          _loadingRequestedUrls.remove(url);
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

  // Add this method to handle back to search categories
  void _handleBackToCategories() {
    setState(() {
      _searchResults = null;
      _setResults = null;
      _showCategories = true;
      _searchController.clear();
      _lastQuery = null;
    });
  }

  // Add this method where the other class methods are
  void _addToSearchHistory(String query, {String? imageUrl}) {
    if (_searchHistory != null) {
      _searchHistory!.addSearch(query, imageUrl: imageUrl);
      // Force rebuild to show new search
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Update the recent searches handler
  void _onRecentSearchSelected(String query, Map<String, String> search) {
    final isSetSearch = search['isSetSearch'] == 'true';
    _searchController.text = isSetSearch ? _formatSearchForDisplay(query) : query;

    // If it's a set search, use set.id format
    if (isSetSearch) {
      _performSearch(query, useOriginalQuery: true);
      return;
    }

    // Check if we have a card to show directly
    if (search['cardId'] != null && search['imageUrl'] != null) {
      // Create a minimal card for navigation
      final card = TcgCard(
        id: search['cardId']!,
        name: query,
        imageUrl: search['imageUrl']!,
        largeImageUrl: search['imageUrl']!.replaceAll('small', 'large'),  // Fix: use replaceAll instead of replace
        set: TcgSet(id: '', name: ''),
      );

      Navigator.pushNamed(
        context,
        '/card',
        arguments: {'card': card},
      );
      return;
    }

    // Default to normal search
    _performSearch(query);
  }

  void _onCameraPressed() async {
    final result = await Navigator.pushNamed(context, '/scanner');
    if (result != null && mounted) {
      final cardData = result as Map<String, dynamic>;
      if (cardData['card'] != null) {
        setState(() {
          _searchController.text = cardData['card'].name;
          _performSearch(_searchController.text);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SearchAppBar(
          searchController: _searchController,
          searchMode: _searchMode,
          currentSort: _currentSort,
          sortAscending: _sortAscending,
          onSearchChanged: _onSearchChanged,
          onSortOptionsPressed: _showSortOptions,
          onSearchModeChanged: (modes) {
            // Fix: Extract the single mode from the set
            setState(() {
              _searchMode = modes.first;
              _searchResults = null;
              _setResults = null;
              _searchController.clear();
              _showCategories = true;
              
              // Always set price high-to-low for MTG mode
              if (_searchMode == SearchMode.mtg) {
                _currentSort = 'cardmarket.prices.averageSellPrice';
                _sortAscending = false;
              }
            });
          },
          onClearSearch: _clearSearch,
          onCameraPressed: _onCameraPressed, // Add this line
        ),
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingState();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Add a simple back button when showing search results
        if (_searchResults != null || _setResults != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: TextButton.icon(
                onPressed: _handleBackToCategories,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Search'),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ),
          
        // ...existing code for search results and categories...
        if (_searchResults == null && _setResults == null) ...[
          SliverToBoxAdapter(
            child: SearchCategoriesHeader(
              showCategories: _showCategories,
              onToggleCategories: () => setState(() => _showCategories = !_showCategories),
            ),
          ),
          if (_showCategories)
            SliverToBoxAdapter(
              child: SearchCategories(
                searchMode: _searchMode,
                onQuickSearch: _performQuickSearch,
              ),
            ),
          SliverToBoxAdapter(
            child: RecentSearches(
              searchHistory: _searchHistory,
              onSearchSelected: (query, search) => _onRecentSearchSelected(query, search),
              onClearHistory: () {
                _searchHistory?.clearHistory();
                setState(() {});
              },
              isLoading: _isHistoryLoading,
            ),
          ),
        ] else ...[
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Text(
                // Fix the text to be accurate about what we're searching
                _searchMode == SearchMode.mtg 
                    ? (_searchResults == null || _searchResults!.isEmpty ? 'Found 0 cards' : 'Found $_totalCards cards')
                    : (_searchMode == SearchMode.eng || _searchMode == SearchMode.jpn) && _setResults != null 
                        ? 'Found ${_setResults?.length ?? 0} sets'
                        : 'Found $_totalCards cards',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          
          // Replace the MTG card grid with this updated version
          if (_searchResults != null && _searchMode == SearchMode.mtg)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,                // Changed from 2 to 3
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final card = _searchResults![index];
                    return CardGridItem(
                      card: card,
                      showName: false,              // Changed to false for better display with 3 columns
                      showPrice: true,              // Keep price display
                      onTap: () {
                        // Save search state before navigating
                        _wasSearchActive = true;
                        _lastActiveSearch = _searchController.text;
                        
                        Navigator.pushNamed(
                          context,
                          '/card',
                          arguments: {'card': card},
                        );
                      },
                    );
                  },
                  childCount: _searchResults!.length,
                ),
              ),
            )
          else if (_searchMode == SearchMode.eng && _searchResults != null)
            CardSearchGrid(
              cards: _searchResults!,
              imageCache: _imageCache,
              loadImage: _loadImage,
              loadingRequestedUrls: _loadingRequestedUrls,
              onCardTap: (card) {
                // Save search state before navigating
                _wasSearchActive = true;
                _lastActiveSearch = _searchController.text;
                
                Navigator.pushNamed(
                  context,
                  '/card',
                  arguments: {'card': card},
                );
              },
            )
          else if (_setResults != null)
            SetSearchGrid(
              sets: _setResults!,
              onSetSelected: (name) {
                _searchController.text = name;
              },
              onSetQuerySelected: (query) {
                _performSearch(query);
              },
            ),
          
          // Handle pagination for all modes
          if (_hasMorePages && !_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: _loadNextPage,
                    child: Text('Load more cards'),
                  ),
                ),
              ),
            ),
          
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

