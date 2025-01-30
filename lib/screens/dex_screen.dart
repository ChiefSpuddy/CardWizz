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

class DexScreen extends StatefulWidget {
  const DexScreen({super.key});

  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  final _namesService = DexNamesService();
  late final DexCollectionService _collectionService;
  final _pokeApi = PokeApiService();
  List<String> _allDexNames = [];
  bool _isLoading = true;
  static const int _pageSize = 30;
  int _currentPage = 0;
  bool _hasMoreItems = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Map<String, dynamic>> _pokemonCache = {};
  String? _selectedGeneration;
  Map<String, int> _collectionCounts = {};

  // Add generation ranges
  final Map<String, (int, int)> _generations = {
    'Gen 1': (1, 151),
    'Gen 2': (152, 251),
    'Gen 3': (252, 386),
    // Add more generations as needed
  };

  @override
  void initState() {
    super.initState();
    _collectionService = DexCollectionService(
      Provider.of<StorageService>(context, listen: false),
    );
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize collection service first
      await _collectionService.initialize();
      
      // Then load initial generation data
      if (_selectedGeneration != null) {
        final (start, end) = _generations[_selectedGeneration]!;
        final stats = await _collectionService.getGenerationStats(start, end);
        _updateGenerationStats(_selectedGeneration!, stats);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
    if (_selectedGeneration == genKey) {
      setState(() {
        _selectedGeneration = null;
        _currentPage = 0;
      });
      return;
    }

    setState(() {
      _selectedGeneration = genKey;
      _currentPage = 0;
      _isLoading = true;
    });

    // Preload the selected generation data
    if (genKey != null) {
      await _preloadGeneration(genKey);
    }

    if (mounted) {
      setState(() => _isLoading = false);
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMoreItems || _isLoading) return;
    
    final startIndex = _currentPage * _pageSize;
    if (startIndex >= _allDexNames.length) {
      setState(() => _hasMoreItems = false);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500)); // Prevent rapid scrolling
    
    if (mounted) {
      setState(() {
        _currentPage++;
        _isLoading = false;
      });
    }
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
    // Use smaller sprites for better performance
    final spriteUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$dexNumber.png';
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _collectionService.getPokemonStats(pokemonName),
          builder: (context, snapshot) {
            final stats = snapshot.data;
            final isCollected = stats?['isCollected'] ?? false;
            final cardCount = stats?['cardCount'] ?? 0;

            return Card(
              elevation: 2,
              color: isCollected ? Colors.green.withOpacity(0.1) : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isCollected 
                  ? () => _showPokemonCards(context, pokemonName, stats?['cards'])
                  : null,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: () async {
                                  final data = _pokemonCache[pokemonName] ?? 
                                             await _pokeApi.fetchPokemon(pokemonName);
                                  if (data != null && context.mounted) {
                                    _showPokemonInfo(context, pokemonName, data);
                                  }
                                },
                                child: Hero(
                                  tag: 'pokemon-$pokemonName',
                                  child: CachedNetworkImage(
                                    imageUrl: spriteUrl,
                                    width: constraints.maxWidth * 0.6,
                                    height: constraints.maxWidth * 0.6,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isCollected)
                            Text(
                              '$cardCount cards',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isCollected)
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
          },
        );
      },
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
    final filteredPokemon = _getFilteredPokemon();
    final itemCount = _hasMoreItems 
      ? min((_currentPage + 1) * _pageSize, filteredPokemon.length) + 1
      : filteredPokemon.length;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= filteredPokemon.length) {
          return _isLoading
            ? const Center(child: CircularProgressIndicator())
            : const SizedBox.shrink();
        }
        
        return _buildPokemonTile(filteredPokemon[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;

    if (!isSignedIn) {
      return const SignInButton(
        message: 'Sign in to view your collection stats',
      );
    }

    final filteredPokemon = _getFilteredPokemon();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
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
                                '€${card.price!.toStringAsFixed(2)}',
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
