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

  // Replace all the old search constants with new organized ones
  static const searchCategories = {
    'vintage': [
      {'name': 'Base Set', 'icon': '📦', 'year': '1999', 'description': 'Original Pokemon TCG set'},
      {'name': 'Jungle', 'icon': '🌿', 'year': '1999', 'description': 'Second Base Set expansion'},
      {'name': 'Fossil', 'icon': '🦴', 'year': '1999', 'description': 'Ancient Pokemon cards'},
      {'name': 'Team Rocket', 'icon': '🚀', 'year': '2000', 'description': 'Evil team themed set'},
      {'name': 'Gym Heroes', 'icon': '🏃', 'year': '2000', 'description': 'Gym Leader cards'},
      {'name': 'Neo Genesis', 'icon': '✨', 'year': '2000', 'description': 'First Neo series set'},
    ],
    'modern': [
      {'name': 'Temporal Forces', 'icon': '⌛', 'release': '2024', 'description': 'Latest expansion'},
      {'name': 'Paradox Rift', 'icon': '🌀', 'release': '2023', 'description': 'Paradox Pokemon'},
      {'name': 'Obsidian Flames', 'icon': '🔥', 'release': '2023', 'description': 'Fire themed set'},
      {'name': 'Paldea Evolved', 'icon': '🌟', 'release': '2023', 'description': 'Paldean Pokemon'},
    ],
    'special': [
      {'name': 'Special Illustration', 'icon': '🎨', 'query': 'rarity:"special illustration rare"', 'description': 'Special art cards'},
      {'name': 'Ancient Pokemon', 'icon': '🗿', 'query': 'ancient', 'description': 'Ancient variant cards'},
      {'name': 'Full Art Trainers', 'icon': '👤', 'query': 'supertype:trainer rarity:rare', 'description': 'Full art trainer cards'},
      {'name': 'Gold Cards', 'icon': '✨', 'query': 'rarity:gold', 'description': 'Gold rare cards'},
    ],
    'popular': [
      {'name': 'Charizard', 'icon': '🔥', 'query': 'name:charizard', 'description': 'All Charizard cards'},
      {'name': 'Mewtwo', 'icon': '🧬', 'query': 'name:mewtwo', 'description': 'All Mewtwo cards'},
      {'name': 'Pikachu', 'icon': '⚡', 'query': 'name:pikachu', 'description': 'All Pikachu cards'},
      {'name': 'Mew', 'icon': '💫', 'query': 'name:mew -mewtwo', 'description': 'All Mew cards'},
    ],
  };

  // Add these fields after other declarations
  int _currentPage = 1;
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  int _totalCards = 0;
  bool _hasMorePages = true;

  // Add cache manager
  static const _maxConcurrentLoads = 3;
  final _loadingImages = <String>{};
  final _imageCache = <String, Image>{};
  final _loadQueue = <String>[];

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

// Update _performSearch method
Future<void> _performSearch(String query, {bool isLoadingMore = false}) async {
  if (query.isEmpty) {
    setState(() => _searchResults = null);
    return;
  }

  // Don't load more if we're already loading or there are no more pages
  if (isLoadingMore && (_isLoading || !_hasMorePages)) {
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
      _isInitialSearch = false;  // Add this line to show loading state
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

// Add this new widget method for scroll indicators
Widget _buildHorizontalScrollView({
  required List<Widget> children,
  required Color indicatorColor,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;

  return Stack(
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 40, 8), // Reduced vertical padding
        child: Row(children: children),
      ),
      Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        child: Container(
          width: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                indicatorColor.withOpacity(0.0),
                isDark 
                    ? colorScheme.surface.withOpacity(0.8)
                    : indicatorColor.withOpacity(0.5),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.chevron_right,
              color: isDark
                  ? colorScheme.onSurface.withOpacity(0.7)
                  : colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    ],
  );
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 120,
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

Widget _buildSearchCard(Map<String, dynamic> item) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: InkWell(
      onTap: () => _performQuickSearch(item['name']),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item['icon'],
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item['description'] ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (item['year'] != null || item['release'] != null)
              Text(
                item['year'] ?? item['release'] ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
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
    padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced from 16 to 8 to increase width
    child: Container(
      decoration: CardStyles.cardDecoration(context),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: CardStyles.gradientDecoration(context),
            child: Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('recentSearches'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _searchHistory?.clearHistory();
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(localizations.translate('clear')),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // Increased from 12 to 16
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searches.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final search = searches[index];
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: search['imageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            search['imageUrl']!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.search),
                ),
                title: Text(
                  search['query']!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  _searchController.text = search['query']!;
                  _performSearch(search['query']!);
                },
              );
            },
          ),
          const SizedBox(height: 8), // Added bottom padding
        ],
      ),
    ),
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

  Widget _buildCard(TcgCard card) {
    final currencyProvider = context.watch<CurrencyProvider>();
    return ListTile(
      // ...existing tile code...
      trailing: Text(
        currencyProvider.formatValue(card.price ?? 0),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGridItem(TcgCard card) {
    final currencyProvider = context.watch<CurrencyProvider>();
    return Card(
      // ...existing card code...
      child: Column(
        children: [
          // ...existing column code...
          Text(
            currencyProvider.formatValue(card.price ?? 0),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            localizations.translate('searchResults'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // ...existing results grid...
      ],
    );
  }

  // Add method to manage image loading
  Future<void> _loadImage(String url) async {
    if (_loadingImages.length >= _maxConcurrentLoads) {
      _loadQueue.add(url);
      return;
    }

    _loadingImages.add(url);
    try {
      final image = Image.network(
        url,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $url');
          return const Icon(Icons.error_outline, color: Colors.red);
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
    if (!_imageCache.containsKey(card.imageUrl) && 
        !_loadingImages.contains(card.imageUrl)) {
      _loadImage(card.imageUrl);
    }

    return CardGridItem(
      card: card,
      showQuickAdd: true,
      cached: _imageCache[card.imageUrl],
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailsScreen(card: card),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          leading: Container(
            margin: const EdgeInsets.only(left: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: () => Navigator.pushNamed(context, '/scanner'),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
          ),
          title: Container(
            height: 40,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    ),
                    style: const TextStyle(fontSize: 15),
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
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
              icon: Icon(_getSortIcon(_currentSort)),
              tooltip: TcgApiService.sortOptions[_currentSort],
              onPressed: _showSortOptions,
            ),
          ],
        ),
        body: _buildMainContent(),
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
    super.dispose();
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildSearchCategories(),
              const SizedBox(height: 8),
              
              // Recent searches when no results
              if (_searchResults == null && !_isLoading) 
                _buildRecentSearches(),
              
              // Loading state
              if (_isLoading && _searchResults == null)
                Padding(
                  padding: const EdgeInsets.only(top: 120.0),
                  child: _buildLoadingState(),
                ),
            ],
          ),
        ),
        
        // Search results
        if (_searchResults != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
          ),
          if (_searchResults!.isEmpty && !_isLoading)
            SliverToBoxAdapter(child: _buildNoResultsMessage())
          else
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
                      return _buildShimmerItem();
                    }
                    return _buildCardGridItem(_searchResults![index]);
                  },
                  childCount: _searchResults!.length + (_isLoading ? 3 : 0),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

