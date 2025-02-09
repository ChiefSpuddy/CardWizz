import '../models/tcg_card.dart';
import 'storage_service.dart';
import 'collection_index_service.dart';  // Update this import
import 'poke_api_service.dart';
import 'dart:async';

class DexCollectionService {
  final StorageService _storage;
  final CollectionIndexService _namesService;  // Update this type
  final PokeApiService _pokeApi;
  final Map<String, bool> _collectionCache = {};
  final Map<String, List<TcgCard>> _cardCache = {};
  List<TcgCard>? _allCards;
  bool _isInitialized = false;
  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  DexCollectionService(this._storage) :
    _namesService = CollectionIndexService(),  // Update constructor
    _pokeApi = PokeApiService() {
    // Make listener more robust
    _storage.onCardsChanged.listen((_) {
      if (!_isRefreshing) {  // Add guard here too
        _refreshCollection();
      }
    });
  }

  Future<void> initialize() async {
    // Clear caches first
    _collectionCache.clear();
    _cardCache.clear();
    _allCards = null;
    _isInitialized = false;
    
    try {
      // Only proceed if we have a user
      if (_storage.currentUserId != null) {
        // Always get fresh cards
        _allCards = await _storage.getCards();
        
        // Rebuild caches
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
    
    // Remove variant suffixes (ex, gx, v, etc)
    normalized = normalized.replaceAll(RegExp(r'\s*(ex|gx|v|vmax|vstar)\b', caseSensitive: false), '');
    
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

  Future<void> refreshCollection() async {
    // Force clear caches
    _collectionCache.clear();
    _cardCache.clear();
    _allCards = null;
    _isInitialized = false;
    
    // Reinitialize with fresh data
    await initialize();
    
    // Notify listeners
    _updateController.add(null);
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
  Map<String, dynamic> getCreatureStats(String creatureName) {
    if (!_isInitialized) return {'isCollected': false, 'cardCount': 0};
    
    final name = creatureName.toLowerCase();
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

  // Update this method to handle Future<List<TcgCard>>
  int getCollectedInRange(int start, int end) {
    if (!_isInitialized || _allCards == null) {
      return 0;
    }
    
    Set<String> collectedCreatures = {};
    
    // Use _allCards which is already loaded in initialize()
    for (var card in _allCards!) {
      final dexNumber = _getDexNumber(card.name);
      if (dexNumber >= start && dexNumber <= end) {
        collectedCreatures.add(dexNumber.toString());
      }
    }
    
    return collectedCreatures.length;
  }

  // Helper method to extract dex number from card name
  int _getDexNumber(String cardName) {
    // Load from names.json if needed
    final normalized = cardName.toLowerCase().trim();
    
    // Try looking up by name first
    final namePattern = RegExp(r'(nidoran[ ]*[♂♀fm]|[a-zA-Z\-]+)');
    final nameMatch = namePattern.firstMatch(normalized);
    
    if (nameMatch != null) {
      final baseName = nameMatch.group(1)?.toLowerCase() ?? '';
      
      // Special case handling
      if (baseName.contains('nidoran')) {
        if (baseName.contains('m') || baseName.contains('♂')) {
          print('Found Nidoran♂ in: $cardName');
          return 32; // Nidoran♂
        } else if (baseName.contains('f') || baseName.contains('♀')) {
          print('Found Nidoran♀ in: $cardName');
          return 29; // Nidoran♀
        }
      }
      
      // Try partial match against known names
      for (final entry in _dexNumbers.entries) {
        if (baseName.startsWith(entry.key)) {
          print('Found ${entry.key} (#${entry.value}) in: $cardName');
          return entry.value;
        }
      }
    }
    
    print('Could not determine dex number for: $cardName');
    return 0;
  }

  // Add this map of known Pokémon names to their dex numbers
  static final Map<String, int> _dexNumbers = {
    'bulbasaur': 1,
    'ivysaur': 2,
    'venusaur': 3,
    'charmander': 4,
    'charmeleon': 5,
    'charizard': 6,
    'squirtle': 7,
    'wartortle': 8,
    'blastoise': 9,
    'caterpie': 10,
    'metapod': 11,
    'butterfree': 12,
    'weedle': 13,
    'kakuna': 14,
    'beedrill': 15,
    'pidgey': 16,
    'pidgeotto': 17,
    'pidgeot': 18,
    'rattata': 19,
    'raticate': 20,
    'spearow': 21,
    'fearow': 22,
    'ekans': 23,
    'arbok': 24,
    'pikachu': 25,
    'raichu': 26,
    'sandshrew': 27,
    'sandslash': 28,
    'nidoran': 29, // Will be handled by special case logic
    'nidorina': 30,
    'nidoqueen': 31,
    'nidorino': 33,
    'nidoking': 34,
    'clefairy': 35,
    'clefable': 36,
    'vulpix': 37,
    'ninetales': 38,
    'jigglypuff': 39,
    'wigglytuff': 40,
    'zubat': 41,
    'golbat': 42,
    'oddish': 43,
    'gloom': 44,
    'vileplume': 45,
    'paras': 46,
    'parasect': 47,
    'venonat': 48,
    'venomoth': 49,
    'diglett': 50,
    'dugtrio': 51,
    'meowth': 52,
    'persian': 53,
    'psyduck': 54,
    'golduck': 55,
    'mankey': 56,
    'primeape': 57,
    'growlithe': 58,
    'arcanine': 59,
    'poliwag': 60,
    'poliwhirl': 61,
    'poliwrath': 62,
    'abra': 63,
    'kadabra': 64,
    'alakazam': 65,
    'machop': 66,
    'machoke': 67,
    'machamp': 68,
    // Add more as needed...
  };

  @override
  void dispose() {
    _updateController.close();
  }
}
