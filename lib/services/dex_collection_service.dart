import '../models/tcg_card.dart';
import 'storage_service.dart';
import 'dex_names_service.dart';
import 'poke_api_service.dart';

class DexCollectionService {
  final StorageService _storage;
  final DexNamesService _namesService;
  final PokeApiService _pokeApi;
  final Map<String, bool> _collectionCache = {};
  final Map<String, List<TcgCard>> _cardCache = {};
  List<TcgCard>? _allCards;
  bool _isInitialized = false;

  DexCollectionService(this._storage) :
    _namesService = DexNamesService(),
    _pokeApi = PokeApiService();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load all cards once
      _allCards = await _storage.getCards();
      
      // Pre-cache collection status and cards in single pass
      for (final card in _allCards!) {
        final baseName = card.name.split(' ')[0].toLowerCase();
        _collectionCache[baseName] = true;
        _cardCache.putIfAbsent(baseName, () => []).add(card);
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing dex collection: $e');
      rethrow;
    }
  }

  bool isPokemonCollected(String pokemonName) {
    return _collectionCache[pokemonName.toLowerCase()] ?? false;
  }

  List<TcgCard> getCardsForPokemon(String pokemonName) {
    return _cardCache[pokemonName.toLowerCase()] ?? [];
  }

  Future<Map<String, dynamic>> getGenerationStats(int startNum, int endNum) async {
    if (!_isInitialized) await initialize();

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
}
