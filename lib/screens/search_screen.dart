import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import '../models/tcg_card.dart';
import '../models/tcg_set.dart';
import '../services/tcg_api_service.dart';
import '../widgets/card_grid.dart';
import '../utils/card_details_router.dart';
import '../services/search_history_service.dart';
import '../services/storage_service.dart';
import '../providers/app_state.dart';
import '../utils/notification_manager.dart';
import '../services/logging_service.dart';
import '../services/tcgdex_api_service.dart';
import '../services/mtg_api_service.dart';
import '../constants/sets.dart';
import '../constants/japanese_sets.dart';
import '../constants/mtg_sets.dart';
import '../utils/image_utils.dart';
import '../utils/card_navigation_helper.dart';
import 'card_details_screen.dart';
import 'search_results_screen.dart';
import '../widgets/search/search_app_bar.dart';
import '../widgets/search/search_categories.dart';
import '../widgets/search/search_categories_header.dart';
import '../widgets/search/recent_searches.dart';
import '../widgets/search/loading_state.dart';
import '../widgets/search/loading_indicators.dart';
import '../widgets/card_grid.dart';
import '../widgets/search/set_grid.dart';
import '../services/navigation_service.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/search/card_skeleton_grid.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/app_drawer.dart';
import '../utils/keyboard_utils.dart'; // Add this import for DismissKeyboardOnTap
import 'package:rxdart/rxdart.dart';
import 'dart:math' as math;
import '../models/tcg_set.dart' as models;

// Import TcgSet from models explicitly
import '../models/tcg_set.dart';

// Then create a typedef to disambiguate
typedef ModelTcgSet = TcgSet;

enum SearchMode { eng, mtg }

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

  // Improve the static setSearchMode method for more robust behavior
  static void setSearchMode(BuildContext context, SearchMode mode) {
    LoggingService.debug('SearchScreen.setSearchMode called with mode: ${mode.toString()}');
    
    // Try to find the state directly
    final state = context.findRootAncestorStateOfType<_SearchScreenState>();
    if (state != null) {
      LoggingService.debug('Found _SearchScreenState directly, calling setSearchMode()');
      state.setSearchMode(mode);
      return;
    }
    
    // If direct state access fails, try to find through Navigator
    LoggingService.debug('Direct state access failed, trying alternate methods');
    final navigatorKey = NavigationService.navigatorKey;
    if (navigatorKey.currentContext != null) {
      final searchState = navigatorKey.currentContext!
          .findRootAncestorStateOfType<_SearchScreenState>();
      if (searchState != null) {
        LoggingService.debug('Found _SearchScreenState through NavigatorKey, calling setSearchMode()');
        searchState.setSearchMode(mode);
        return;
      }
    }
    
    // Last resort - use a global method that will be picked up on next frame
    LoggingService.debug('Unable to find _SearchScreenState, using delayed approach');
    _pendingSearchMode = mode;
    
    // Schedule a check after rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingSearchMode(context);
    });
  }
  
  // Add this static field to track pending mode changes
  static SearchMode? _pendingSearchMode;
  
  // Add this helper method to check for pending mode changes
  static void _checkPendingSearchMode(BuildContext context) {
    if (_pendingSearchMode != null) {
      LoggingService.debug('Applying pending search mode: ${_pendingSearchMode.toString()}');
      
      // Try all methods to find the search screen state
      final state = context.findRootAncestorStateOfType<_SearchScreenState>();
      if (state != null) {
        state.setSearchMode(_pendingSearchMode!);
        _pendingSearchMode = null;
        return;
      }
      
      // Schedule another check if we still can't find it
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_pendingSearchMode != null) {
          _checkPendingSearchMode(context);
        }
      });
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

  // Add this field to store theme provider
  late final ThemeProvider _themeProvider;

  // Add this field at the top of the class with other fields
  String? _currentSetName;

  // Add this field
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add this field to store cards in memory
  final _collectionCardsSubject = BehaviorSubject<Set<String>>.seeded({});
  Set<String> get _collectionCardIds => _collectionCardsSubject.value;
  StreamSubscription? _cardsSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initSearchHistory();
    
    // Simplify - Remove the pendingSearchMode check
    
    // Listen for theme changes to refresh the UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Store provider reference for later use
      _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      // Add the listener
      _themeProvider.addListener(_onThemeChanged);
      
      // Handle initial search if provided
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['initialSearch'] != null) {
        _searchController.text = args['initialSearch'] as String;
        _performSearch(_searchController.text);
      }
      
      // Remove NavigationService.applyPendingSearchMode call
    });

    // Setup the collection watcher
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCollectionWatcher();
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
        // Remove NavigationService.applyPendingSearchMode call
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
    // Clean up theme change listener
    _themeProvider.removeListener(_onThemeChanged);
    
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    
    // CRITICAL FIX: Cancel subscription before closing stream
    _cardsSubscription?.cancel();
    
    // Only close if not already closed
    if (!_collectionCardsSubject.isClosed) {
      _collectionCardsSubject.close();
    }
    
    super.dispose();
  }
  
  // Add this method to handle theme changes
  void _onThemeChanged() {
    // Force a rebuild of the UI on theme change
    if (mounted) {
      setState(() {
        // No need to update any state values - just trigger a rebuild
      });
    }
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
      LoggingService.debug('Error initializing search history: $e');
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

    // Update to store set name for better loading states
    String? setName;

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
          
          // Extract set name for display in loading state
          final setId = query.substring(7).trim();
          final allSets = _getAllSets();
          final matchingSet = allSets.firstWhere(
            (set) => (set['query'] as String?)?.contains(setId) ?? false,
            orElse: () => {'name': null},
          );
          setName = matchingSet['name'] as String?;
          _currentSetName = setName; // Store for skeleton loader
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

        // AGGRESSIVE IMAGE PRELOADING - Start loading ALL images IMMEDIATELY
        // This ensures images show up without requiring scrolling or interaction
        if (newCards.isNotEmpty) {
          LoggingService.debug("Starting aggressive image preloading for ${newCards.length} cards");
          
          // Directly load the first 12 images synchronously (first 4 rows)
          for (int i = 0; i < math.min(12, newCards.length); i++) {
            if (newCards[i].imageUrl != null) {
              _loadImage(newCards[i].imageUrl!);
            }
          }
          
          // Update the state quickly to show cards while images are loading
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
          });
          
          // Then queue the rest for loading after a tiny delay to not block UI
          Future.delayed(Duration.zero, () {
            for (int i = 12; i < newCards.length; i++) {
              if (newCards[i].imageUrl != null) {
                if (!_loadingRequestedUrls.contains(newCards[i].imageUrl)) {
                  if (_loadingImages.length < _maxConcurrentLoads) {
                    _loadImage(newCards[i].imageUrl!);
                  } else {
                    _loadQueue.add(newCards[i].imageUrl!);
                  }
                }
              }
            }
          });
          
          // ...search history code...
        } else {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      LoggingService.debug('❌ Search error: $e');
      if (mounted) {
        setState(() {
          if (!isLoadingMore) {
            _searchResults = [];
            _totalCards = 0;
          }
        });
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
        LoggingService.debug('MTG search for set: "$originalSetCode" using query: "$searchQuery" (sorted by price high-to-low)');
      } else {
        LoggingService.debug('MTG general search: "$searchQuery" (sorted by price high-to-low)');
      }

      final results = await _mtgApi.searchCards(
        query: searchQuery,
        page: _currentPage,
        pageSize: 30,
        orderBy: _currentSort,        // Already set to price
        orderByDesc: !_sortAscending, // Already set to descending (high to low)
      );

      if (mounted) {
        final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
        final List<dynamic> cardsData = results['data'] as List? ?? [];
        final int totalCount = results['totalCount'] as int;
        final bool hasMore = results['hasMore'] ?? false;
        
        LoggingService.debug('MTG API returned ${cardsData.length} cards, total: $totalCount, hasMore: $hasMore');
        
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
        
        // Convert to TcgCard objects with currency conversion
        final cards = cardsData.map((data) {
          final eurPrice = data['price'] as double? ?? 0.0;
          return TcgCard(
            id: data['id'] as String? ?? '',
            name: data['name'] as String? ?? 'Unknown Card',
            imageUrl: data['imageUrl'] as String? ?? '',
            largeImageUrl: data['largeImageUrl'] as String? ?? '',
            number: data['number'] as String? ?? '',
            rarity: data['rarity'] as String? ?? '',
            price: currencyProvider.convertFromEur(eurPrice),
            set: models.TcgSet( // Not models.TcgSet
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
            LoggingService.debug('Card $i: ${cards[i].name} - ${cards[i].imageUrl}');
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
      LoggingService.debug('MTG search error: $e');
      LoggingService.debug('Stack trace: $stack');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _searchResults = [];
          _totalCards = 0;
          _hasMorePages = false;
        });
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
          LoggingService.debug('Error fetching MTG set details: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _setResults = [];
            });
          }
        }
      }
    } catch (e) {
      LoggingService.debug('Set search error: $e');
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
    
    // Use a shorter debounce for better responsiveness
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && query == _searchController.text && query.isNotEmpty) {
        setState(() {
          _currentPage = 1;
          _isInitialSearch = true;
          _isLoading = true; // Set loading state before search for immediate UI feedback
        });
        
        // Perform search based on mode
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
      // Fix: Use title for display if name is missing
      _searchController.text = searchItem['title'] ?? searchItem['name'] ?? searchItem['query'] ?? '';
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
      LoggingService.debug('Quick search error: $e');
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

  // Improved image loading
  Future<void> _loadImage(String url) async {
    // If already loading or cached, skip
    if (_loadingRequestedUrls.contains(url) || _imageCache.containsKey(url)) {
      return;
    }

    // Mark as requested to avoid duplicate requests
    _loadingRequestedUrls.add(url);
    
    // Use a simpler, more reliable Image.network approach
    try {
      // Create the image
      final img = Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Image fully loaded
            return child;
          }
          // Show a loading indicator while loading
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          _loadingRequestedUrls.remove(url);
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.white),
            ),
          );
        },
      );
      
      // Cache the image immediately
      _imageCache[url] = img;
      
      // Use a listener to know when the image is fully loaded
      final completer = Completer<bool>();
      
      // Ensure the image is actually loaded with timeout
      final imageProvider = NetworkImage(url);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final listener = ImageStreamListener(
        (info, synchronousCall) {
          if (!completer.isCompleted) {
            completer.complete(true);
            _loadingImages.remove(url);
            
            // Process next image in queue
            if (_loadQueue.isNotEmpty) {
              final nextUrl = _loadQueue.removeAt(0);
              _loadImage(nextUrl);
            }
          }
        },
        onError: (exception, stackTrace) {
          if (!completer.isCompleted) {
            completer.complete(false);
            _loadingRequestedUrls.remove(url);
            _loadingImages.remove(url);
            
            // Process next image in queue
            if (_loadQueue.isNotEmpty) {
              final nextUrl = _loadQueue.removeAt(0);
              _loadImage(nextUrl);
            }
          }
        },
      );
      
      imageStream.addListener(listener);
      
      // Add a timeout
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(false);
          _loadingRequestedUrls.remove(url);
          _loadingImages.remove(url);
          imageStream.removeListener(listener);
          
          // Process next image in queue
          if (_loadQueue.isNotEmpty) {
            final nextUrl = _loadQueue.removeAt(0);
            _loadImage(nextUrl);
          }
        }
      });
      
      _loadingImages.add(url);

    } catch (e) {
      LoggingService.debug('Error requesting image: $e');
      _loadingRequestedUrls.remove(url);
      _loadingImages.remove(url);
      
      // Process next image in queue
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
      // Only add if we have a valid query
      if (query.isNotEmpty) {
        _searchHistory!.addSearch(query, imageUrl: imageUrl);
        // Force rebuild to show new search
        if (mounted) {
          setState(() {});
        }
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
        set: models.TcgSet(id: '', name: ''),
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

  void _onCardTap(TcgCard card) {
    // FIXED: Use the CardNavigationHelper for consistent navigation
    CardNavigationHelper.navigateToCardDetails(
      context, 
      card,
      heroContext: 'search_${card.id}'
    );
  }

  // Fix the fundamental issue in _onCardAddToCollection
  Future<void> _onCardAddToCollection(TcgCard card) async {
    try {
      // Get services without context rebuilding
      final appState = Provider.of<AppState>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Update the collection card IDs to reflect the addition immediately
      // This makes the UI update without waiting for the save
      _collectionCardsSubject.add({..._collectionCardIds, card.id});
      
      // Save the card in the background
      await storageService.saveCard(card, preventNavigation: true);
      
      // Notify app state AFTER save completes
      appState.notifyCardChange();
      
      // Provide tactile feedback
      HapticFeedback.mediumImpact();
      
      // CRITICAL FIX: Use NotificationManager instead of BottomNotification
      NotificationManager.success(
        context,
        message: 'Added ${card.name} to collection',
        icon: Icons.add_circle_outline,
        preventNavigation: true,
        position: NotificationPosition.bottom,
      );
    } catch (e) {
      // If error occurs, remove from local collection
      _collectionCardsSubject.add(
        _collectionCardIds.where((id) => id != card.id).toSet()
      );
      
      // CRITICAL FIX: Use NotificationManager for consistency
      NotificationManager.error(
        context,
        message: 'Failed to add card: $e',
        icon: Icons.error_outline,
      );
    }
  }

  // Replace the entire build method with this elegant implementation
  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DismissKeyboardOnTap( // Wrap the Scaffold with this widget
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        // Replace the StandardAppBar with our SearchAppBar
        appBar: SearchAppBar(
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onClearSearch: _clearSearch,
          currentSort: _currentSort,
          sortAscending: _sortAscending,
          onSortOptionsPressed: _showSortOptions,
          hasResults: _searchResults != null || _setResults != null,
          searchMode: _searchMode,
          onSearchModeChanged: (modes) {
            setState(() {
              _searchMode = modes.first;
              _clearSearch();
            });
          },
          onCameraPressed: _onCameraPressed,
          onCancelSearch: _handleBackToCategories, // Add this line to handle search cancellation
        ),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Back to categories button when showing results
            if (_searchResults != null || _setResults != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: TextButton.icon(
                    onPressed: _handleBackToCategories,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Categories'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              
            // Content sections
            if (_searchResults == null && _setResults == null && !_isLoading) ...[
              // Categories header
              SliverToBoxAdapter(
                child: SearchCategoriesHeader(
                  showCategories: _showCategories,
                  onToggleCategories: () => setState(() => _showCategories = !_showCategories),
                ),
              ),
              
              // Categories grid when expanded
              if (_showCategories)
                SliverToBoxAdapter(
                  child: SearchCategories(
                    searchMode: _searchMode,
                    onQuickSearch: _performQuickSearch,
                  ),
                ),
              
              // Recent searches
              SliverToBoxAdapter(
                child: RecentSearches(
                  searchHistory: _searchHistory,
                  onSearchSelected: _onRecentSearchSelected,
                  onClearHistory: () {
                    _searchHistory?.clearHistory();
                    setState(() {});
                  },
                  isLoading: _isHistoryLoading,
                ),
              ),
              
            ] else if (_isLoading && _searchResults == null && _setResults == null) ...[
              // Loading state
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    _currentSetName != null
                        ? 'Loading cards from $_currentSetName...'
                        : 'Searching for "${_searchController.text}"...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              
              // Skeleton loading grid
              CardSkeletonGrid(
                itemCount: 12,
                setName: _currentSetName,
              ),
              
            ] else ...[
              // Results count header
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    _searchMode == SearchMode.mtg
                        ? (_searchResults == null || _searchResults!.isEmpty ? 'Found 0 cards' : 'Found $_totalCards cards')
                        : (_searchMode == SearchMode.eng) && _setResults != null
                            ? 'Found ${_setResults?.length ?? 0} sets'
                            : 'Found $_totalCards cards',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              
              // Results grid - cards or sets
              if (_searchResults != null && _searchMode == SearchMode.mtg)
                CardGridSliver(
                  cards: _searchResults!.cast<TcgCard>(),
                  onCardTap: (card) {
                    CardDetailsRouter.navigateToCardDetails(context, card, heroContext: 'search');
                  },
                  preventNavigationOnQuickAdd: true,
                  showPrice: true,
                  showName: true,
                  heroContext: 'search',
                  crossAxisCount: 3,
                )
              else if (_searchMode == SearchMode.eng && _searchResults != null)
                CardGridSliver(
                  cards: _searchResults!.cast<TcgCard>(),
                  onCardTap: (card) {
                    CardDetailsRouter.navigateToCardDetails(context, card, heroContext: 'search');
                  },
                  preventNavigationOnQuickAdd: true,
                  showPrice: true,
                  showName: true,
                  heroContext: 'search',
                  crossAxisCount: 3,
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
              
              // Pagination controls
              if (_hasMorePages && !_isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _loadNextPage,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load More'),
                    ),
                  ),
                ),
              
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Add this method to watch collection changes
  void _setupCollectionWatcher() {
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    // Store the subscription for later cleanup
    _cardsSubscription = storageService.watchCards().listen((cards) {
      // Only add to stream if it's not closed and the widget is mounted
      if (!_collectionCardsSubject.isClosed && mounted) {
        final cardIds = cards.map((c) => c.id).toSet();
        _collectionCardsSubject.add(cardIds);
      }
    });
  }

  // Update this method to be more robust and add debug logging
  void setSearchMode(SearchMode mode) {
    LoggingService.debug('_SearchScreenState.setSearchMode called with mode: ${mode.toString()}');
    LoggingService.debug('Current mode: $_searchMode');
    
    if (_searchMode != mode) {
      setState(() {
        _searchMode = mode;
        _clearSearch();
        
        // Reset sort ordering based on mode
        if (_searchMode == SearchMode.mtg) {
          _currentSort = 'cardmarket.prices.averageSellPrice';
          _sortAscending = false;
        } else {
          _currentSort = 'number';
          _sortAscending = true;
        }
        
        LoggingService.debug('Mode changed to: $_searchMode');
      });
    } else {
      LoggingService.debug('No mode change needed - already in mode: $_searchMode');
    }
  }
  
  // Update to use our single setSearchMode method
  void _onSearchModeChanged(List<SearchMode> modes) {
    setSearchMode(modes.first);
  }

  // In your search function, after getting results:
  void _showSearchResults(List<TcgCard> results, String searchTerm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          cards: results,
          searchTerm: searchTerm,
        ),
      ),
    );
  }
}

