import '../models/tcg_card.dart';
import 'storage_service.dart';
import 'dex_names_service.dart';
import 'poke_api_service.dart';

class DexCollectionService {
  final StorageService _storage;
  final DexNamesService _namesService;
  final PokeApiService _pokeApi;
  Map<String, Map<String, dynamic>> _statsCache = {};
  List<TcgCard>? _cardsCache;
  Map<String, bool> _collectionMap = {};
  bool _isInitialized = false;
  
  DexCollectionService(this._storage) : 
    _namesService = DexNamesService(),
    _pokeApi = PokeApiService();

  // Initialize collection data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final cards = await _storage.getCards();
    _cardsCache = cards;
    
    // Create quick lookup map for collection status
    _collectionMap = {
      for (var card in cards)
        card.name.split(' ')[0].toLowerCase(): true
    };
    
    _isInitialized = true;
  }

  // Fast synchronous check if a Pokemon is collected
  bool isPokemonCollected(String pokemonName) {
    return _collectionMap[pokemonName.toLowerCase()] ?? false;
  }

  // Get cards for a specific Pokemon
  List<TcgCard> getCardsForPokemon(String pokemonName) {
    return _cardsCache?.where((card) => 
      card.name.toLowerCase().contains(pokemonName.toLowerCase())
    ).toList() ?? [];
  }

  // Add missing getAllCards method
  Future<List<TcgCard>> getAllCards() async {
    return await _storage.getCards();
  }

  // Fix the getGenerationStats method
  Future<Map<String, dynamic>> getGenerationStats(int startNum, int endNum) async {
    final cacheKey = 'gen_${startNum}_$endNum';
    if (_statsCache.containsKey(cacheKey)) {
      return _statsCache[cacheKey]!;
    }

    if (!_isInitialized) {
      await initialize();
    }

    final stats = <String, dynamic>{
      'cardCount': 0,
      'totalValue': 0.0,
      'uniquePokemon': 0,
      'collectedPokemon': <String>[],
      'spriteUrls': <String, String>{},
    };

    // Get all Pokemon data in batches
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
    _statsCache[cacheKey] = stats;
    return stats;
  }

  // Get Pokemon stats with caching
  Future<Map<String, dynamic>> getPokemonStats(String pokemonName) async {
    final cacheKey = 'pokemon_$pokemonName';
    if (_statsCache.containsKey(cacheKey)) {
      return _statsCache[cacheKey]!;
    }

    try {
      final cards = await getAllCards();
      final pokemonCards = cards.where((card) => 
        card.name.toLowerCase().contains(pokemonName.toLowerCase())
      ).toList();

      final stats = {
        'isCollected': pokemonCards.isNotEmpty,
        'cardCount': pokemonCards.length,
        'totalValue': pokemonCards.fold<double>(
          0,
          (sum, card) => sum + (card.price ?? 0),
        ),
        'cards': pokemonCards,
      };

      _statsCache[cacheKey] = stats;
      return stats;
    } catch (e) {
      print('Error getting pokemon stats: $e');
      return {
        'isCollected': false,
        'cardCount': 0,
        'totalValue': 0.0,
        'cards': <TcgCard>[],
      };
    }
  }

  // Clear cache when needed
  void clearCache() {
    _statsCache.clear();
    _cardsCache = null;
  }

  Future<Map<String, dynamic>> getDexStats(String setName) async {
    try {
      final cards = await getAllCards();
      final setCards = cards.where((card) => card.setName == setName).toList();

      return {
        'cardCount': setCards.length,
        'totalValue': setCards.fold<double>(
          0,
          (sum, card) => sum + (card.price ?? 0),
        ),
        'variants': setCards.map((card) => card.number).toSet().length,
        'cards': setCards,
      };
    } catch (e) {
      print('Error getting dex stats: $e');
      return {
        'cardCount': 0,
        'totalValue': 0.0,
        'variants': 0,
        'cards': <TcgCard>[],
      };
    }
  }

  // Get overall dex completion stats
  Future<Map<String, dynamic>> getDexCompletionStats() async {
    final cards = await getAllCards();
    final uniquePokemon = cards
        .map((card) => card.name.split(' ')[0]) // Get base Pokémon name
        .toSet()
        .length;

    return {
      'collected': uniquePokemon,
      'totalValue': cards.fold<double>(
        0,
        (sum, card) => sum + (card.price ?? 0)),
    };
  }
}
