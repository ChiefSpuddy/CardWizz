import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';  // Add this import
import '../models/tcg_card.dart';  // Add this import
import '../services/dex_names_service.dart';
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

class DexScreen extends StatefulWidget {
  const DexScreen({super.key});

  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _namesService = DexNamesService();
  late final DexCollectionService _collectionService;
  final _pokeApi = PokeApiService();
  List<String> _allDexNames = [];
  bool _isLoading = true;
  static const int _pageSize = 50;  // Increased page size for smoother scroll
  int _currentPage = 0;
  bool _hasMoreItems = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Map<String, dynamic>> _pokemonCache = {};
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
      _collectionCounts[genKey] = stats['uniquePokemon'];
      _pokemonCache.addAll(
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

  Color _getTypeColor(String type) {
    final colors = {
      'NORMAL': Colors.grey[400]!,
      'FIRE': Colors.deepOrange,
      'WATER': Colors.blue,
      'ELECTRIC': Colors.amber,
      'GRASS': Colors.green,
      'ICE': Colors.lightBlue,
      'FIGHTING': Colors.brown[700]!,
      'POISON': Colors.purple,
      'GROUND': Colors.brown,
      'FLYING': Colors.indigo[200]!,
      'PSYCHIC': Colors.pink,
      'BUG': Colors.lightGreen,
      'ROCK': Colors.grey[700]!,
      'GHOST': Colors.deepPurple,
      'DRAGON': Colors.indigo,
      'DARK': Colors.grey[900]!,
      'STEEL': Colors.blueGrey,
      'FAIRY': Colors.pinkAccent,
    };
    return colors[type] ?? Colors.grey;
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

    final visibleRange = _getFilteredPokemon().sublist(
      firstVisible.clamp(0, _allDexNames.length),
      lastVisible.clamp(0, _allDexNames.length),
    );

    _visibleItems.clear();
    _visibleItems.addAll(visibleRange);
    
    // Preload next batch of sprites
    _preloadSprites(lastVisible, lastVisible + 20);
  }

  Future<void> _preloadSprites(int start, int end) async {
    final pokemon = _getFilteredPokemon();
    final validEnd = end.clamp(0, pokemon.length);
    
    for (var i = start; i < validEnd; i++) {
      final name = pokemon[i];
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
    final names = await _namesService.loadDexNames();
    if (mounted) {
      setState(() {
        _allDexNames = names;
        _isLoading = false;  // Remove the parenthesis here
      });  // Fix the closure
      // Preload first page of Pokemon data
      _preloadPokemonData(0, _pageSize);
    }
  }

  Future<void> _preloadPokemonData(int start, int count) async {
    final end = min(start + count, _allDexNames.length);
    for (var i = start; i < end; i++) {
      final name = _allDexNames[i];
      if (!_pokemonCache.containsKey(name)) {
        _pokemonCache[name] = await _pokeApi.fetchPokemon(name) ?? {};
      }
    }
  }

  Future<void> _showPokemonInfo(BuildContext context, String pokemonName, Map<String, dynamic> data) {
    final types = (data['types'] as List?)?.map((t) => t['type']['name'].toString().toUpperCase()).toList() ?? [];
    final height = ((data['height'] ?? 0) / 10).toStringAsFixed(1); // convert to meters
    final weight = ((data['weight'] ?? 0) / 10).toStringAsFixed(1); // convert to kg
    final stats = data['stats'] as List? ?? [];
    
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getTypeColor(types.firstOrNull ?? '').withOpacity(0.2),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getTypeColor(types.firstOrNull ?? '').withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '#${_namesService.getDexNumber(pokemonName).toString().padLeft(3, '0')}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            pokemonName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                Hero(
                  tag: 'pokemon-$pokemonName',
                  child: CachedNetworkImage(
                    imageUrl: data['sprites']['other']['official-artwork']['front_default'] ?? '',
                    height: 200,
                    width: 200,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: types.map((type) => 
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Chip(
                              backgroundColor: _getTypeColor(type),
                              label: Text(
                                type,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        ).toList(),
                      ),
                      const SizedBox(height: 16),
                      ...stats.map((stat) => _buildStatBar(
                        stat['stat']['name'].toString(),
                        stat['base_stat'] as int,
                      )),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard('Height', '$height m'),
                          _buildStatCard('Weight', '$weight kg'),
                        ],
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

  Widget _buildStatBar(String statName, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              statName.toUpperCase(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 255, // Max stat value
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatColor(value),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatColor(int value) {
    if (value >= 150) return Colors.green;
    if (value >= 90) return Colors.lime;
    if (value >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonTile(String pokemonName) {
    final dexNumber = _namesService.getDexNumber(pokemonName);
    final spriteUrl = _pokeApi.getSpriteUrl(dexNumber);
    final stats = _collectionService.getPokemonStats(pokemonName);
    
    return Card(
      elevation: 2,
      color: stats['isCollected'] ? Colors.green.withOpacity(0.1) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: stats['isCollected'] 
          ? () => _showPokemonCards(context, pokemonName, stats['cards'])
          : null,
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,  // Center the content
              children: [
                Expanded(
                  child: Center(  // Center the image
                    child: GestureDetector( // Add tap handler for Pokemon info
                      onTap: () async {
                        final data = await _pokeApi.fetchPokemon(dexNumber.toString());
                        if (data != null && mounted) {
                          _showPokemonInfo(context, pokemonName, data);
                        }
                      },
                      child: CachedNetworkImage(
                        imageUrl: spriteUrl,
                        fit: BoxFit.contain,
                        width: 80,  // Fixed width for consistent sizing
                        height: 80,  // Fixed height for consistent sizing
                        placeholder: (context, url) => const SizedBox(
                          width: 80,
                          height: 80,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                        pokemonName,
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

  List<String> _getFilteredPokemon() {
    if (_selectedGeneration == null) return _allDexNames;
    
    final (start, end) = _generations[_selectedGeneration]!;
    return _allDexNames.where((name) {
      final dexNum = _namesService.getDexNumber(name);
      return dexNum >= start && dexNum <= end;
    }).toList();
  }

  Future<double> _getCollectionProgress(List<String> pokemon) async {
    if (pokemon.isEmpty) return 0;
    final collected = await _getCollectedCount(pokemon);
    return collected / pokemon.length;
  }

  Future<int> _getCollectedCount(List<String> pokemon) async {
    int count = 0;
    for (final name in pokemon) {
      final stats = await _collectionService.getPokemonStats(name);
      if (stats['isCollected'] == true) count++;
    }
    return count;
  }

  Widget _buildPokemonGrid() {
    if (_allDexNames.isEmpty) {
      return const Center(
        child: Text('No Pokémon found. Please try again.'),
      );
    }

    final filteredPokemon = _getFilteredPokemon();
    
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
        key: PageStorageKey('pokemon_grid'),  // Preserve scroll position
        controller: _scrollController,
        padding: const EdgeInsets.all(_gridSpacing),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridCrossAxisCount,
          childAspectRatio: _aspectRatio,
          crossAxisSpacing: _gridSpacing,
          mainAxisSpacing: _gridSpacing,
        ),
        itemCount: filteredPokemon.length,
        itemBuilder: (context, index) => _buildPokemonTile(filteredPokemon[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;
    final currencyProvider = context.watch<CurrencyProvider>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),  // Remove scaffoldKey parameter
      appBar: AppBar(
        toolbarHeight: 44, // Match other screens
        automaticallyImplyLeading: true,
      ),
      body: !isSignedIn  // Removed AnimatedBackground
          ? const SignInView()
          : Column(
              children: [
                _buildGenerationProgress(),
                Expanded(
                  child: _isLoading && _currentPage == 0
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPokemonGrid(),
                ),
              ],
            ),
    );
  }

  void _showPokemonCards(BuildContext context, String pokemonName, List<TcgCard> cards) {
    final currencyProvider = context.read<CurrencyProvider>();  // Add this
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            AppBar(
              title: Text('$pokemonName Cards'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailsScreen(card: card),
                      ),
                    ),
                    child: Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              card.imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (card.price != null)
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                currencyProvider.formatValue(card.price!),  // Update this line
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
