import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';  // Add this import
import '../models/tcg_card.dart';  // Add this import
import '../services/collection_index_service.dart';  // Update this import
import '../services/dex_collection_service.dart';
import '../services/storage_service.dart';
import '../widgets/sign_in_button.dart';
import '../providers/app_state.dart';
import 'card_details_screen.dart';
import '../services/poke_api_service.dart';
import 'dart:math';  // Add this import for min()
import 'dart:async';  // Add this import for StreamSubscription
import '../widgets/app_drawer.dart';  // Add this import
import '../providers/currency_provider.dart';  // Add this import
import '../widgets/sign_in_view.dart';  // Add this import
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';  // Add this import
import '../constants/colors.dart';  // Add this import
import 'dart:ui';  // Add this import at the top with other imports

class CollectionIndexScreen extends StatefulWidget {
  const CollectionIndexScreen({super.key});

  @override
  State<CollectionIndexScreen> createState() => _CollectionIndexScreenState();
}

class _CollectionIndexScreenState extends State<CollectionIndexScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _namesService = CollectionIndexService();  // Update this line
  late final DexCollectionService _collectionService;
  final _pokeApi = PokeApiService();
  List<String> _allDexNames = [];
  bool _isLoading = true;
  static const int _pageSize = 50;  // Increased page size for smoother scroll
  int _currentPage = 0;
  bool _hasMoreItems = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Map<String, dynamic>> _creatureCache = {};
  String? _selectedGeneration;
  Map<String, int> _collectionCounts = {};

  // Update generation ranges
  final Map<String, (int, int)> _generations = {
    'Gen 1': (1, 151),
    'Gen 2': (152, 251),
    'Gen 3': (252, 386),
    'Gen 4': (387, 493),
    'Gen 5': (494, 649),
    'Gen 6': (650, 721),
    'Gen 7': (722, 809),
    'Gen 8': (810, 905),
    'Gen 9': (906, 1008),
  };

  // Add grid layout constants
  static const double _gridSpacing = 8.0;
  static const double _aspectRatio = 0.9;  // Slightly wider for better sprite alignment
  static const int _gridCrossAxisCount = 3;

  bool _isInitialized = false;
  StreamSubscription? _updateSubscription;
  bool _isRefreshing = false;

  // Add viewport tracking
  final _visibleItems = <String>{};

  @override
  void initState() {
    super.initState();
    _collectionService = DexCollectionService(
      Provider.of<StorageService>(context, listen: false),
    );
    _scrollController.addListener(_onScroll);
    
    // Update listener to handle updates more efficiently
    _updateSubscription = _collectionService.onUpdate.listen((_) {
      if (mounted && !_isRefreshing) {
        _refreshDex();
      }
    });
    
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshIfNeeded();
  }

  void _refreshIfNeeded() {
    if (_isInitialized && mounted) {
      _refreshDex();
    }
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Initialize collection service
      await _collectionService.initialize();
      _isInitialized = true;  // Mark as initialized
      
      // Load first generation by default
      _selectedGeneration = 'Gen 1';
      final (start, end) = _generations['Gen 1']!;
      
      // Load names and update UI immediately when they're available
      _allDexNames = await _namesService.loadGenerationNames(start, end);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Load stats after UI is shown
      final stats = await _collectionService.getGenerationStats(start, end);
      if (mounted) {
        _updateGenerationStats('Gen 1', stats);
      }
      
    } catch (e) {
      print('Error initializing dex: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _allDexNames = [];  // Ensure we have an empty list rather than null
        });
      }
    }
  }

  Future<void> _refreshDex() async {
    if (!mounted || _isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      if (_selectedGeneration != null) {
        final (start, end) = _generations[_selectedGeneration]!;
        final stats = await _collectionService.getGenerationStats(start, end);
        
        if (mounted) {
          setState(() {
            _updateGenerationStats(_selectedGeneration!, stats);
          });
        }
      }
    } catch (e) {
      print('Error refreshing dex: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _updateGenerationStats(String genKey, Map<String, dynamic> stats) {
    if (!mounted) return;
    setState(() {
      _collectionCounts[genKey] = stats['uniqueCreatures'];
      _creatureCache.addAll(
        (stats['spriteUrls'] as Map<String, String>).map(
          (name, url) => MapEntry(name, {'sprite': url}),
        ),
      );
    });
  }

  Future<void> _preloadGeneration(String genKey) async {
    if (!_generations.containsKey(genKey)) return;
    
    final (start, end) = _generations[genKey]!;
    await _collectionService.getGenerationStats(start, end);
  }

  Future<void> _selectGeneration(String? genKey) async {
    if (!mounted || _isRefreshing || genKey == _selectedGeneration) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (genKey != null) {
        final (start, end) = _generations[genKey]!;
        _allDexNames = await _namesService.loadGenerationNames(start, end);
        _selectedGeneration = genKey;
        
        final stats = await _collectionService.getGenerationStats(start, end);
        
        if (mounted) {
          setState(() {
            _updateGenerationStats(genKey, stats);
            _currentPage = 0;
          });
        }
      }
    } catch (e) {
      print('Error loading generation: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _checkVisibleItems();
    // Load more when reaching 80% of the list
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreItems();
    }
  }

  void _checkVisibleItems() {
    if (!mounted) return;
    
    final RenderBox? gridBox = context.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final viewport = gridBox.paintBounds;
    final firstVisible = (_scrollController.position.pixels / gridBox.size.height * _gridCrossAxisCount).floor();
    final lastVisible = (((_scrollController.position.pixels + viewport.height) / 
        gridBox.size.height) * _gridCrossAxisCount).ceil();

    final visibleRange = _getFilteredCreatures().sublist(
      firstVisible.clamp(0, _allDexNames.length),
      lastVisible.clamp(0, _allDexNames.length),
    );

    _visibleItems.clear();
    _visibleItems.addAll(visibleRange);
    
    // Preload next batch of sprites
    _preloadSprites(lastVisible, lastVisible + 20);
  }

  Future<void> _preloadSprites(int start, int end) async {
    final creatures = _getFilteredCreatures();
    final validEnd = end.clamp(0, creatures.length);
    
    for (var i = start; i < validEnd; i++) {
      final name = creatures[i];
      final dexNumber = _namesService.getDexNumber(name);
      final spriteUrl = _pokeApi.getSpriteUrl(dexNumber);
      
      // Preload sprite image
      precacheImage(NetworkImage(spriteUrl), context);
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMoreItems || _isLoading) return;
    
    setState(() => _isLoading = true);
    
    final startIndex = _currentPage * _pageSize;
    if (startIndex >= _allDexNames.length) {
      setState(() {
        _hasMoreItems = false;
        _isLoading = false;
      });
      return;
    }

    _currentPage++;
    setState(() => _isLoading = false);
  }

  Future<void> _loadDexNames() async {
    setState(() => _isLoading = true);
    
    try {
      // Use existing method loadGenerationNames instead
      final (start, end) = _generations['Gen 1']!;
      final names = await _namesService.loadGenerationNames(start, end);
      
      if (mounted) {
        setState(() {
          _allDexNames = names;
          _isLoading = false;
        });
        
        // Preload first page of creature data
        _preloadCreatureData(0, _pageSize);
      }
    } catch (e) {
      print('Error loading dex names: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _allDexNames = [];
        });
      }
    }
  }

  Future<void> _preloadCreatureData(int start, int count) async {
    final end = min(start + count, _allDexNames.length);
    for (var i = start; i < end; i++) {
      final name = _allDexNames[i];
      if (!_creatureCache.containsKey(name)) {
        _creatureCache[name] = await _pokeApi.fetchPokemon(name) ?? {};
      }
    }
  }

  Future<void> _showCreatureInfo(BuildContext context, String creatureName, Map<String, dynamic> data) {
    final height = ((data['height'] ?? 0) / 10).toStringAsFixed(1);
    final weight = ((data['weight'] ?? 0) / 10).toStringAsFixed(1);
    final stats = data['stats'] as List? ?? [];
    final creatureStats = _collectionService.getCreatureStats(creatureName);
    final cards = creatureStats['cards'] as List<TcgCard>? ?? [];
    final currencyProvider = context.read<CurrencyProvider>();
    final speciesData = _pokeApi.fetchSpeciesData(_namesService.getDexNumber(creatureName));

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                // Modern top bar with gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.8),
                        Colors.blue.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text(
                                '#${_namesService.getDexNumber(creatureName).toString().padLeft(3, '0')}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Hero(
                          tag: 'creature-$creatureName',
                          child: CachedNetworkImage(
                            imageUrl: data['sprites']['other']['official-artwork']['front_default'] ?? '',
                            height: 180,
                            width: 180,
                          ),
                        ),
                        Text(
                          creatureName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 16),
                        // Modern tabs
                        TabBar(
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Info', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.style, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Cards (${cards.length})', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      // Info tab with modern styling
                      LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          controller: scrollController,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildInfoCard(
                                    'Physical Attributes',
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildAttributeColumn(
                                          icon: Icons.height,
                                          label: 'Height',
                                          value: '$height m',
                                          color: Colors.blue,
                                        ),
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.grey[300],
                                        ),
                                        _buildAttributeColumn(
                                          icon: Icons.monitor_weight,
                                          label: 'Weight',
                                          value: '$weight kg',
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: speciesData,
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) return const SizedBox.shrink();
                                      
                                      final flavorText = snapshot.data!['flavor_text'];
                                      final habitat = snapshot.data!['habitat'];
                                      
                                      return _buildInfoCard(
                                        'Dex Entry',
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (flavorText != null)
                                              Text(
                                                flavorText,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.5,
                                                  fontStyle: FontStyle.italic,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                                ),
                                              ),
                                            if (habitat != null) ...[
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.landscape,
                                                    size: 16,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Habitat: ${habitat[0].toUpperCase()}${habitat.substring(1)}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoCard(
                                    'Base Stats',
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: stats.map((stat) {
                                        final value = stat['base_stat'] as int;
                                        return _buildModernStatBar(
                                          _formatStatName(stat['stat']['name'].toString().toUpperCase()),
                                          value,
                                          Colors.blue,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Cards tab with modern styling
                      cards.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.style_outlined, 
                                    size: 48, 
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No cards collected yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: cards.length,
                              itemBuilder: (context, index) => _buildCardTile(
                                cards[index],
                                currencyProvider,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatBar(String name, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 255,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTile(TcgCard card, CurrencyProvider currencyProvider) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailsScreen(card: card),
        ),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  card.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (card.price != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Text(
                  currencyProvider.formatValue(card.price!),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatureTile(String creatureName) {
    final dexNumber = _namesService.getDexNumber(creatureName);
    final spriteUrl = _pokeApi.getSpriteUrl(dexNumber);
    final stats = _collectionService.getCreatureStats(creatureName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      color: stats['isCollected']
          ? (isDark ? AppColors.pokemonTileCollectedDark : AppColors.pokemonTileCollected)
          : (isDark ? AppColors.pokemonTileUncollectedDark : AppColors.pokemonTileUncollected),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final data = await _pokeApi.fetchPokemon(dexNumber.toString());
          if (data != null && mounted) {
            _showCreatureInfo(context, creatureName, data);
          }
        },
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: spriteUrl,
                      fit: BoxFit.contain,
                      width: 80,
                      height: 80,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(16),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            creatureName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      Text(
                        '#${dexNumber.toString().padLeft(3, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        creatureName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (stats['isCollected'])
                        Text(
                          '${stats['cardCount']} cards',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (stats['isCollected'])
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationProgress() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _generations.length,
        itemBuilder: (context, index) {
          final gen = _generations.entries.elementAt(index);
          final (start, end) = gen.value;
          final isSelected = _selectedGeneration == gen.key;
          final collectedCount = _collectionCounts[gen.key] ?? 0;
          final totalCount = end - start + 1;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 120,
              child: InkWell(
                onTap: () => _selectGeneration(gen.key),
                child: Card(
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? Colors.green.withOpacity(0.1) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          gen.key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.green : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: totalCount > 0 ? collectedCount / totalCount : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSelected ? Colors.green : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$collectedCount/$totalCount',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.green : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getFilteredCreatures() {
    if (_selectedGeneration == null) return _allDexNames;
    
    final (start, end) = _generations[_selectedGeneration]!;
    return _allDexNames.where((name) {
      final dexNum = _namesService.getDexNumber(name);
      return dexNum >= start && dexNum <= end;
    }).toList();
  }

  Future<double> _getCollectionProgress(List<String> creatures) async {
    if (creatures.isEmpty) return 0;
    final collected = await _getCollectedCount(creatures);
    return collected / creatures.length;
  }

  Future<int> _getCollectedCount(List<String> creatures) async {
    int count = 0;
    for (final name in creatures) {
      final stats = await _collectionService.getCreatureStats(name);
      if (stats['isCollected'] == true) count++;
    }
    return count;
  }

  Widget _buildCreatureGrid() {
    if (_allDexNames.isEmpty) {
      return const Center(
        child: Text('No creatures found. Please try again.'),
      );
    }

    final filteredCreatures = _getFilteredCreatures();
    
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Load more when reaching 80% of the list
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
            _loadMoreItems();
          }
        }
        return false;
      },
      child: GridView.builder(
        key: PageStorageKey('creature_grid'),  // Preserve scroll position
        controller: _scrollController,
        padding: const EdgeInsets.all(_gridSpacing),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridCrossAxisCount,
          childAspectRatio: _aspectRatio,
          crossAxisSpacing: _gridSpacing,
          mainAxisSpacing: _gridSpacing,
        ),
        itemCount: filteredCreatures.length,
        itemBuilder: (context, index) => _buildCreatureTile(filteredCreatures[index]),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Column(
      children: [
        // Shimmer effect for generation tabs
        Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(_gridSpacing),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridCrossAxisCount,
              childAspectRatio: _aspectRatio,
              crossAxisSpacing: _gridSpacing,
              mainAxisSpacing: _gridSpacing,
            ),
            itemCount: 18, // Show a reasonable number of shimmer tiles
            itemBuilder: (context, index) => _buildLoadingTile(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingTile() {
    return Card(
      elevation: 2,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 12,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 10,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // Update the build method to use the new loading screen
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
            ),
          ),
        ),
        toolbarHeight: 44,
        automaticallyImplyLeading: true,
      ),
      body: Stack(
        children: [
          // Add animated background
          Lottie.asset(
            'assets/animations/background.json',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Main content
          !isSignedIn
              ? const SignInView()
              : Column(
                  children: [
                    _buildGenerationProgress(),
                    Expanded(
                      child: _isLoading && _currentPage == 0
                          ? const Center(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                            )
                          : _buildCreatureGrid(),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  // Update creature tile to show loading state
  Widget _buildCreatureTileWithLoading(String creatureName) {
    final dexNumber = _namesService.getDexNumber(creatureName);
    final spriteUrl = _pokeApi.getSpriteUrl(dexNumber);
    final stats = _collectionService.getCreatureStats(creatureName);
    
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: spriteUrl,
                    fit: BoxFit.contain,
                    width: 80,
                    height: 80,
                    fadeInDuration: const Duration(milliseconds: 300),
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          creatureName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ...existing creature info code...
            ],
          ),
          if (stats['isCollected'])
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
        ],
      ),
    );
  }

  String _formatStatName(String name) {
    switch (name) {
      case 'HP':
        return 'HP';
      case 'ATTACK':
        return 'Attack';
      case 'DEFENSE':
        return 'Defense';
      case 'SPECIAL-ATTACK':
        return 'Sp. Atk';
      case 'SPECIAL-DEFENSE':
        return 'Sp. Def';
      case 'SPEED':
        return 'Speed';
      default:
        return name;
    }
  }
}