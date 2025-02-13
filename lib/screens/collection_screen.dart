import 'dart:async';
import 'poke_api_service.dart';
import 'collection_index_service.dart';  // Make sure this import is used
import 'storage_service.dart';
import '../models/tcg_card.dart';

class CollectionTrackingService {
  final StorageService _storage;
  final PokeApiService _pokeApi;
  final CollectionIndexService _namesService;  // Update this type
  final Map<String, List<TcgCard>> _cardCache = {};
  final Map<String, bool> _collectionCache = {};
  List<TcgCard>? _allCards;
  bool _isInitialized = false;
  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  CollectionTrackingService(this._storage)
      : _pokeApi = PokeApiService(),
        _namesService = CollectionIndexService() {
    _storage.onCardsChanged.listen((_) {
      if (!_isRefreshing) {  // Add guard here too
        _refreshCollection();
      }
    });
  }

  Future<void> initialize() async {
    _isInitialized = false;
    _allCards = null;
    _cardCache.clear();
    _collectionCache.clear();
    // Clear caches first
    try {
      if (_storage.prefs.getString('user_id') != null) {
        // Only proceed if we have a user
        _allCards = await _storage.getCards();
        // Always get fresh cards
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
    return cardName.toLowerCase()
      .replaceAll(RegExp(r'\s*(ex|gx|v|vmax|vstar|★|\*)\b'), '')
      .replaceAll(RegExp(r'alolan\s+'), '')
      .replaceAll(RegExp(r'galarian\s+'), '')
      .replaceAll(RegExp(r'hisuian\s+'), '')
      .trim();
  }

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

  Future<void> refresh() async {
    await _refreshCollection();
  }

  Future<void> refreshCollection() async {
    // Force clear caches
    _isInitialized = false;
    _allCards = null;
    _cardCache.clear();
    _collectionCache.clear();
    // Reinitialize with fresh data
    await initialize();
    // Notify listeners
    _updateController.add(null);
  }

  bool isCardCollected(String name) {
    final normalized = _normalizeCardName(name);
    final isCollected = _collectionCache[normalized] ?? false;
    return isCollected;
  }

  List<TcgCard> getCardsForName(String name) {
    final normalized = _normalizeCardName(name);
    return _cardCache[normalized] ?? [];
  }

  Future<Map<String, dynamic>> getSetStats(int startNum, int endNum) async {
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
    final dexNumbers = List.generate(endNum - startNum + 1, (i) => startNum + i);
    final pokemonData = await _pokeApi.fetchPokemonBatch(dexNumbers);
    for (final data in pokemonData) {
      final name = data['name'].toString();
      (stats['spriteUrls'] as Map<String, String>)[name] = data['sprite'];
      if (isCardCollected(name)) {
        (stats['collectedPokemon'] as List<String>).add(name);
        final cards = getCardsForName(name);
        stats['cardCount'] = (stats['cardCount'] as int) + cards.length;
        stats['totalValue'] = (stats['totalValue'] as double) +
            cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
      }
    }
    stats['uniquePokemon'] = (stats['collectedPokemon'] as List).length;
    return stats;
  }

  Map<String, dynamic> getCardStats(String name) {
    if (!_isInitialized) return {'isCollected': false, 'cardCount': 0};
    final normalized = name.toLowerCase();
    final cards = _cardCache[normalized] ?? [];
    return {
      'isCollected': _collectionCache[normalized] ?? false,
      'cardCount': cards.length,
      'totalValue': cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0)),
      'cards': cards,
    };
  }

  void clearCache() {
    _collectionCache.clear();
    _cardCache.clear();
    _allCards = null;
    _isInitialized = false;
  }

  int getCollectedInRange(int start, int end) {
    if (!_isInitialized || _allCards == null) {
      return 0;
    }
    Set<String> collectedCreatures = {};
    for (var card in _allCards!) {
      final dexNumber = _getDexNumber(card.name);
      if (dexNumber >= start && dexNumber <= end) {
        collectedCreatures.add(dexNumber.toString());
      }
    }
    return collectedCreatures.length;
  }

  int getCollectedCount(int start, int end) {
    if (!_isInitialized || _allCards == null) return 0;
    Set<int> collectedNumbers = {};
    for (var card in _allCards!) {
      final name = _normalizeCardName(card.name);
      final dexNumber = _getDexNumber(name);
      if (dexNumber >= start && dexNumber <= end) {
        collectedNumbers.add(dexNumber);
      }
    }
    return collectedNumbers.length;
  }

  int _getDexNumber(String cardName) {
    // Special cases first
    final specialCases = {
      'nidoran♂': 32,
      'nidoran♀': 29,
      'mr. mime': 122,
      'mime jr': 439,
      'farfetch\'d': 83,
      // Add more special cases as needed
    };
    for (final entry in specialCases.entries) {
      if (cardName.contains(entry.key)) {
        return entry.value;
      }
    }
    // Try to match against the name mapping
    for (final entry in _dexNumbers.entries) {
      if (cardName.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return 0;
  }

  static final Map<String, int> _dexNumbers = {
    // Add this map of known Pokémon names to their dex numbers
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
    // Add Series 2 (Generation 2) mappings
    'chikorita': 152,
    'bayleef': 153,
    'meganium': 154,
    'cyndaquil': 155,
    'quilava': 156,
    'typhlosion': 157,
    'totodile': 158,
    'croconaw': 159,
    'feraligatr': 160,
    'sentret': 161,
    'furret': 162,
    'hoothoot': 163,
    'noctowl': 164,
    'ledyba': 165,
    'ledian': 166,
    'spinarak': 167,
    'ariados': 168,
    'crobat': 169,
    'chinchou': 170,
    'lanturn': 171,
    'pichu': 172,
    'cleffa': 173,
    'igglybuff': 174,
    'togepi': 175,
    'togetic': 176,
    'natu': 177,
    'xatu': 178,
    'mareep': 179,
    'flaaffy': 180,
    'ampharos': 181,
    'bellossom': 182,
    'marill': 183,
    'azumarill': 184,
    'sudowoodo': 185,
    'politoed': 186,
    'hoppip': 187,
    'skiploom': 188,
    'jumpluff': 189,
    'aipom': 190,
    'sunkern': 191,
    'sunflora': 192,
    'yanma': 193,
    'wooper': 194,
    'quagsire': 195,
    'espeon': 196,
    'umbreon': 197,
    'murkrow': 198,
    'slowking': 199,
    'misdreavus': 200,
    'unown': 201,
    'wobbuffet': 202,
    'girafarig': 203,
    'pineco': 204,
    'forretress': 205,
    'dunsparce': 206,
    'gligar': 207,
    'steelix': 208,
    'snubbull': 209,
    'granbull': 210,
    'qwilfish': 211,
    'scizor': 212,
    'shuckle': 213,
    'heracross': 214,
    'sneasel': 215,
    'teddiursa': 216,
    'ursaring': 217,
    'slugma': 218,
    'magcargo': 219,
    'swinub': 220,
    'piloswine': 221,
    'corsola': 222,
    'remoraid': 223,
    'octillery': 224,
    'delibird': 225,
    'mantine': 226,
    'skarmory': 227,
    'houndour': 228,
    'houndoom': 229,
    'kingdra': 230,
    'phanpy': 231,
    'donphan': 232,
    'porygon2': 233,
    'stantler': 234,
    'smeargle': 235,
    'tyrogue': 236,
    'hitmontop': 237,
    'smoochum': 238,
    'elekid': 239,
    'magby': 240,
    'miltank': 241,
    'blissey': 242,
    'raikou': 243,
    'entei': 244,
    'suicune': 245,
    'larvitar': 246,
    'pupitar': 247,
    'tyranitar': 248,
    'lugia': 249,
    'ho-oh': 250,
    'celebi': 251,
    // Add Series 3 (Generation 3) mappings
    'treecko': 252,
    'grovyle': 253,
    'sceptile': 254,
    'torchic': 255,
    'combusken': 256,
    'blaziken': 257,
    'mudkip': 258,
    'marshtomp': 259,
    'swampert': 260,
    'poochyena': 261,
    'mightyena': 262,
    'zigzagoon': 263,
    'linoone': 264,
    'wurmple': 265,
    'silcoon': 266,
    'beautifly': 267,
    'cascoon': 268,
    'dustox': 269,
    'lotad': 270,
    'lombre': 271,
    'ludicolo': 272,
    'seedot': 273,
    'nuzleaf': 274,
    'shiftry': 275,
    'taillow': 276,
    'swellow': 277,
    'wingull': 278,
    'pelipper': 279,
    'ralts': 280,
    'kirlia': 281,
    'gardevoir': 282,
    'surskit': 283,
    'masquerain': 284,
    'shroomish': 285,
    'breloom': 286,
    'slakoth': 287,
    'vigoroth': 288,
    'slaking': 289,
    'nincada': 290,
    'ninjask': 291,
    'shedinja': 292,
    'whismur': 293,
    'loudred': 294,
    'exploud': 295,
    'makuhita': 296,
    'hariyama': 297,
    'azurill': 298,
    'nosepass': 299,
    'skitty': 300,
    'delcatty': 301,
    'sableye': 302,
    'mawile': 303,
    'aron': 304,
    'lairon': 305,
    'aggron': 306,
    'meditite': 307,
    'medicham': 308,
    'electrike': 309,
    'manectric': 310,
    'plusle': 311,
    'minun': 312,
    'volbeat': 313,
    'illumise': 314,
    'roselia': 315,
    'gulpin': 316,
    'swalot': 317,
    'carvanha': 318,
    'sharpedo': 319,
    'wailmer': 320,
    'wailord': 321,
    'numel': 322,
    'camerupt': 323,
    'torkoal': 324,
    'spoink': 325,
    'grumpig': 326,
    'spinda': 327,
    'trapinch': 328,
    'vibrava': 329,
    'flygon': 330,
    'cacnea': 331,
    'cacturne': 332,
    'swablu': 333,
    'altaria': 334,
    'zangoose': 335,
    'seviper': 336,
    'lunatone': 337,
    'solrock': 338,
    'barboach': 339,
    'whiscash': 340,
    'corphish': 341,
    'crawdaunt': 342,
    'baltoy': 343,
    'claydol': 344,
    'lileep': 345,
    'cradily': 346,
    'anorith': 347,
    'armaldo': 348,
    'feebas': 349,
    'milotic': 350,
    'castform': 351,
    'kecleon': 352,
    'shuppet': 353,
    'banette': 354,
    'duskull': 355,
    'dusclops': 356,
    'tropius': 357,
    'chimecho': 358,
    'absol': 359,
    'wynaut': 360,
    'snorunt': 361,
    'glalie': 362,
    'spheal': 363,
    'sealeo': 364,
    'walrein': 365,
    'clamperl': 366,
    'huntail': 367,
    'gorebyss': 368,
    'relicanth': 369,
    'luvdisc': 370,
    'bagon': 371,
    'shelgon': 372,
    'salamence': 373,
    'beldum': 374,
    'metang': 375,
    'metagross': 376,
    'regirock': 377,
    'regice': 378,
    'registeel': 379,
    'latias': 380,
    'latios': 381,
    'kyogre': 382,
    'groudon': 383,
    'rayquaza': 384,
    'jirachi': 385,
    'deoxys': 386,
    // Add more as needed...
  };

  @override
  void dispose() {
    _updateController.close();
  }
}

// ...existing code...
itemBuilder: (context, index) {
  final card = cards[index];
  return CardTile(
    card: card,
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailsScreen(
          card: card,
          heroContext: 'collection_${card.id}',  // Make tag unique
        ),
      ),
    ),
    heroTag: 'collection_${card.id}',  // Make tag unique
  );
},
// ...existing code...