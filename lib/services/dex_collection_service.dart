import '../models/tcg_card.dart';
import 'storage_service.dart';
import 'dex_names_service.dart';
import 'poke_api_service.dart';
import 'dart:async';

class DexCollectionService {
  final StorageService _storage;
  final DexNamesService _namesService;
  final PokeApiService _pokeApi;
  final Map<String, bool> _collectionCache = {};
  final Map<String, List<TcgCard>> _cardCache = {};
  List<TcgCard>? _allCards;
  bool _isInitialized = false;
  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  DexCollectionService(this._storage) :
    _namesService = DexNamesService(),
    _pokeApi = PokeApiService() {
    // Make listener more robust
    _storage.onCardsChanged.listen((_) {
      if (!_isRefreshing) {  // Add guard here too
        _refreshCollection();
      }
    });
  }

  Future<void> initialize() async {
    if (_isInitialized && _storage.currentUserId != null) return;
    
    try {
      // Clear caches first
      _collectionCache.clear();
      _cardCache.clear();
      _allCards = null;
      _isInitialized = false;
      
      // Only proceed if we have a user
      if (_storage.currentUserId != null) {
        _allCards = await _storage.getCards();
        
        // Build new caches
        for (final card in _allCards!) {
          final baseName = _normalizeCardName(card.name);
          _collectionCache[baseName] = true;
          
          if (!_cardCache.containsKey(baseName)) {
            _cardCache[baseName] = [];
          }
          if (!_cardCache[baseName]!.any((c) => c.id == card.id)) {
            _cardCache[baseName]!.add(card);
          }
        }
        
        _isInitialized = true;
        print('DexCollection initialized with ${_allCards?.length ?? 0} cards');
      } else {
        print('DexCollection initialize skipped - no user');
      }
    } catch (e) {
      print('Error initializing dex collection: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  String _normalizeCardName(String cardName) {
    final specialCases = {
      'mr.': 'mr',
      'mr ': 'mr',
      'farfetch\'d': 'farfetchd',
      'mime jr.': 'mime jr',
      'mime jr ': 'mime jr',
    };

    String normalized = cardName.toLowerCase().trim();
    
    for (final entry in specialCases.entries) {
      if (normalized.startsWith(entry.key)) {
        normalized = normalized.replaceFirst(entry.key, entry.value);
      }
    }

    final baseNamePattern = RegExp(r'^([a-zA-Z\-]+)');
    final match = baseNamePattern.firstMatch(normalized);
    return match?.group(1) ?? normalized;
  }

  bool _isRefreshing = false;  // Add this flag

  // Make refresh more robust
  Future<void> _refreshCollection() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    try {
      await initialize();  // This will handle all the cache clearing
      _updateController.add(null);
    } finally {
      _isRefreshing = false;
    }
  }

  // Public refresh method
  Future<void> refresh() async {
    await _refreshCollection();
  }

  bool isPokemonCollected(String pokemonName) {
    final normalized = _normalizeCardName(pokemonName);
    final isCollected = _collectionCache[normalized] ?? false;
    return isCollected;
  }

  List<TcgCard> getCardsForPokemon(String pokemonName) {
    final normalized = _normalizeCardName(pokemonName);
    return _cardCache[normalized] ?? [];
  }

  // Update getGenerationStats to use the correct method name
  Future<Map<String, dynamic>> getGenerationStats(int startNum, int endNum) async {
    if (!_isInitialized) {
      await refresh();
    }

    final stats = {
      'cardCount': 0,
      'totalValue': 0.0,
      'uniquePokemon': 0,
      'collectedPokemon': <String>[],
      'spriteUrls': <String, String>{},
    };

    // Get sprite URLs in batch
    final dexNumbers = List.generate(endNum - startNum + 1, (i) => startNum + i);
    final pokemonData = await _pokeApi.fetchPokemonBatch(dexNumbers);

    for (final data in pokemonData) {
      final name = data['name'].toString();
      (stats['spriteUrls'] as Map<String, String>)[name] = data['sprite'];
      
      if (isPokemonCollected(name)) {
        (stats['collectedPokemon'] as List<String>).add(name);
        final cards = getCardsForPokemon(name);
        stats['cardCount'] = (stats['cardCount'] as int) + cards.length;
        stats['totalValue'] = (stats['totalValue'] as double) + 
          cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
      }
    }

    stats['uniquePokemon'] = (stats['collectedPokemon'] as List).length;
    return stats;
  }

  // Simplified Pokemon stats
  Map<String, dynamic> getPokemonStats(String pokemonName) {
    if (!_isInitialized) return {'isCollected': false, 'cardCount': 0};
    
    final name = pokemonName.toLowerCase();
    final cards = _cardCache[name] ?? [];
    
    return {
      'isCollected': _collectionCache[name] ?? false,
      'cardCount': cards.length,
      'totalValue': cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0)),
      'cards': cards,
    };
  }

  // Clear cache when needed
  void clearCache() {
    _collectionCache.clear();
    _cardCache.clear();
    _allCards = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _updateController.close();
  }
}
