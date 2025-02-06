import 'dart:convert';
import 'dart:math' show min;  // Add this import
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';  // Add this import
import '../models/tcg_card.dart';  // Add this import

class TcgApiService {
  static final TcgApiService _instance = TcgApiService._internal();
  final http.Client _client = http.Client();
  final Dio _dio;  // Add this field
  final _cache = <String, (DateTime, dynamic)>{};
  final _cacheDuration = const Duration(hours: 1);

  factory TcgApiService() {
    return _instance;
  }

  TcgApiService._internal() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {'X-Api-Key': _apiKey},
  ));

  Future<void> dispose() async {
    _client.close();
  }

  static const String _baseUrl = 'https://api.pokemontcg.io/v2';
  static const String _apiKey = 'eebb53a0-319a-4231-9244-fd7ea48b5d2c';
  
  // Add these new constants
  static const Map<String, String> quickSearchQueries = {
    'Rare Cards': 'rarity:"Rare Holo" OR rarity:"Rare Ultra" OR rarity:"Rare Secret"',
    'Full Art': 'supertype:"Pokémon" types:"Full Art"',
    'Rainbow': 'rarity:"Rare Rainbow"',
    'Gold Cards': 'rarity:"Rare Secret"',
  };

  static const Map<String, String> popularSearchQueries = {
    'Charizard': 'name:"charizard"',
    'Pikachu': 'name:"pikachu"',
    'Mew': 'name:"mew"',
    'Ex Cards': 'subtypes:"Pokemon ex"',  // Fixed query
    'VMAX': 'subtypes:"VMAX"',  // Fixed query
    'Special Illustration Rare': 'rarity:"Special Illustration Rare"',  // New query replacing Trainer Gallery
  };

  // Update the maps to remove duplicates
  static const Map<String, String> setSearchQueries = {
    'Prismatic Evolution': 'set.id:pr',
    'Surging Sparks': 'set.id:sv8',
    'Shrouded Fables': 'set.id:sv9',
    'Pokemon 151': 'set.id:sv3pt5',
    'Temporal Forces': 'set.id:sv5',
    'Paradox Rift': 'set.id:sv4',
    'Obsidian Flames': 'set.id:sv3',
    'Paldea Evolved': 'set.id:sv2',
    // Add vintage sets
    'Base Set': 'set.id:base1',
    'Jungle': 'set.id:base2',
    'Fossil': 'set.id:base3',
    'Team Rocket': 'set.id:base5',
    'Gym Heroes': 'set.id:gym1',
    'Gym Challenge': 'set.id:gym2',
    'Neo Genesis': 'set.id:neo1',
    'Neo Discovery': 'set.id:neo2',
    'Neo Revelation': 'set.id:neo3',
    'Neo Destiny': 'set.id:neo4',
  };

  static const Map<String, String> sortOptions = {
    'cardmarket.prices.averageSellPrice': 'Price (High to Low)',
    '-cardmarket.prices.averageSellPrice': 'Price (Low to High)',
    'name': 'Name (A to Z)',
    '-name': 'Name (Z to A)',
    'set.releaseDate': 'Release Date (Newest)',
    '-set.releaseDate': 'Release Date (Oldest)',
  };

  // Remove the first setAliases declaration and keep only this one
  static const Map<String, String> setAliases = {
    // Modern sets
    'astral radiance': 'swsh10',
    'brilliant stars': 'swsh9',
    'steam siege': 'xy11',
    'crown zenith': 'swsh12pt5',
    'silver tempest': 'swsh12',
    'temporal forces': 'sv3p5',
    // XY series sets
    'phantom forces': 'xy4',
    'roaring skies': 'xy6',
    'ancient origins': 'xy7',
    'breakpoint': 'xy9',
    'breakthrough': 'xy8',
    'evolutions': 'xy12',
    'fates collide': 'xy10',
    'flashfire': 'xy2',
    'furious fists': 'xy3',
    'generations': 'g1',
    'primal clash': 'xy5',
    'hidden fates': 'sm115',
    // Partial matches and alternative spellings
    'prismatic': 'sve',
    'paradox': 'sv4',
    'obsidian': 'sv3',
    'paldea': 'sv2',
    'scarlet': 'sv1',
    'steam seige': 'xy11',  // Common misspelling
    'astral': 'swsh10',     // Partial match
    'brilliant': 'swsh9',   // Partial match
    'hidden fate': 'sm115', // Singular form
  };

  // Replace the old list-based setAliases with a new setNameVariants map
  static const Map<String, List<String>> setNameVariants = {
    'sv8.5': ['Prismatic Evolution', 'Prismatic', 'Evolution'],
    'sv8': ['Surging Sparks', 'Surging', 'Sparks'],
    'sv7': ['Stellar Crown', 'Stellar', 'Crown'],
    'sv6': ['Twilight Masquerade', 'Twilight', 'Masquerade'],
    'sv5': ['Paldean Fates', 'Temporal Forces', 'Paldean', 'Fates', 'Temporal'],
    'sv4': ['Paradox Rift', 'Paradox', 'Rift'],
    'sv3': ['Obsidian Flames', 'Obsidian', 'Flames'],
    'sv3p5': ['Temporal Forces', 'Temporal', 'Forces'],
    'sv2': ['Paldea Evolved', 'Paldea', 'Evolved'],
  };

  static const Map<String, String> setIdMap = {
    'team rocket returns': 'ex7',
    'lost origin': 'swsh11',
    'vivid voltage': 'swsh4',
    'astral radiance': 'swsh10',
    'brilliant stars': 'swsh9',
    'steam siege': 'xy11',
    'crown zenith': 'swsh12pt5',
    'silver tempest': 'swsh12',
    'temporal forces': 'sv3p5',
    'paradox rift': 'sv4',
    'obsidian flames': 'sv3',
    'paldea evolved': 'sv2',
  };

  static const Map<String, String> allSetIds = {
    // Sword & Shield Era
    'fusion strike': 'swsh8',
    'brilliant stars': 'swsh9',
    'astral radiance': 'swsh10',
    'pokemon go expansion': 'pgo',  // Changed key to avoid duplicate
    'lost origin': 'swsh11',
    'silver tempest': 'swsh12',
    'crown zenith': 'swsh12pt5',
    'celebrations': 'cel25',
    'evolving skies': 'swsh7',
    'chilling reign': 'swsh6',
    'battle styles': 'swsh5',
    'shining fates': 'swsh45',
    'vivid voltage': 'swsh4',
    'champions path': 'swsh35',
    'darkness ablaze': 'swsh3',
    'rebel clash': 'swsh2',
    'sword & shield base': 'swsh1',
    
    // Scarlet & Violet Era
    'paldean fates': 'sv5',
    'temporal forces': 'sv3p5',
    'paradox rift': 'sv4',
    'obsidian flames': 'sv3',
    '151': 'sv3pt5',
    'paldea evolved': 'sv2',
    'scarlet & violet base': 'sv1',
    
    // Sun & Moon Era
    'cosmic eclipse': 'sm12',
    'hidden fates': 'sm115',
    'unified minds': 'sm11',
    'unbroken bonds': 'sm10',
    'team up': 'sm9',
    'lost thunder': 'sm8',
    'dragon majesty': 'sm75',
    'celestial storm': 'sm7',
    'forbidden light': 'sm6',
    'ultra prism': 'sm5',
    'crimson invasion': 'sm4',
    'shining legends': 'sm35',
    'burning shadows': 'sm3',
    'guardians rising': 'sm2',
    'sun & moon base': 'sm1',
    
    // XY Era
    'evolutions': 'xy12',
    'steam siege': 'xy11',
    'fates collide': 'xy10',
    'generations': 'g1',
    'breakpoint': 'xy9',
    'breakthrough': 'xy8',
    'ancient origins': 'xy7',
    'roaring skies': 'xy6',
    'primal clash': 'xy5',
    'phantom forces': 'xy4',
    'furious fists': 'xy3',
    'flashfire': 'xy2',
    'xy base set': 'xy1',
    
    // Black & White Era
    'legendary treasures': 'bw11',
    'plasma blast': 'bw10',
    'plasma freeze': 'bw9',
    'plasma storm': 'bw8',
    'boundaries crossed': 'bw7',
    'dragons exalted': 'bw6',
    'dark explorers': 'bw5',
    'next destinies': 'bw4',
    'noble victories': 'bw3',
    'emerging powers': 'bw2',
    'black & white base': 'bw1',
    
    // HeartGold SoulSilver Era
    'call of legends': 'col',
    'triumphant': 'hgss4',
    'undaunted': 'hgss3',
    'unleashed': 'hgss2',
    'heartgold soulsilver': 'hgss1',
    
    // Platinum Era
    'arceus': 'pl4',
    'supreme victors': 'pl3',
    'rising rivals': 'pl2',
    'platinum base': 'pl1',
    
    // Diamond & Pearl Era
    'stormfront': 'dp7',
    'legends awakened': 'dp6',
    'majestic dawn': 'dp5',
    'great encounters': 'dp4',
    'secret wonders': 'dp3',
    'mysterious treasures': 'dp2',
    'diamond & pearl base': 'dp1',
    
    // EX Series
    'power keepers': 'ex16',
    'dragon frontiers': 'ex15',
    'crystal guardians': 'ex14',
    'holon phantoms': 'ex13',
    'legend maker': 'ex12',
    'delta species': 'ex11',
    'unseen forces': 'ex10',
    'emerald': 'ex9',
    'deoxys': 'ex8',
    'team rocket returns': 'ex7',
    'fire red & leaf green': 'ex6',
    'hidden legends': 'ex5',
    'team magma vs team aqua': 'ex4',
    'dragon': 'ex3',
    'sandstorm': 'ex2',
    'ruby & sapphire': 'ex1',
    
    // E-Card Series
    'skyridge': 'ecard3',
    'aquapolis': 'ecard2',
    'expedition': 'ecard1',
    
    // Neo Series
    'neo destiny': 'neo4',
    'neo revelation': 'neo3',
    'neo discovery': 'neo2',
    'neo genesis': 'neo1',
    
    // Gym Series
    'gym challenge': 'gym2',
    'gym heroes': 'gym1',
    
    // Base Set Era
    'legendary collection': 'base6',
    'team rocket': 'base5',
    'base set 2': 'base4',
    'fossil': 'base3',
    'jungle': 'base2',
    'base set': 'base1',
    
    // Special Sets & Promos
    'pokemon go series': 'pgo',  // Changed key to be more specific
    'celebrations classic': 'cel25c',
    'shining fates subset': 'swsh45sv',
    'champions path promos': 'swsh35',
    'detective pikachu': 'det1',
    'dragon vault': 'dv1',
    'double crisis': 'dc1',
    'radiant collection': 'rc1',
    'pop series promos': 'pop1',
    'southern islands': 'si1',
    'black star promos': 'bsp',
    
    // Special search mappings
    'delta': 'subtypes:"delta species"',
    'ancient': 'subtypes:ancient',
    'trainer gallery': 'subtypes:"trainer gallery"',
    'shining': 'subtypes:shining',
  };

  final _headers = {
    'X-Api-Key': _apiKey,
  };

  Map<String, String> _buildSearchQuery(String searchTerm) {
    searchTerm = searchTerm.trim();
    
    // First try to match a card number pattern (e.g., "048/091" or "48/91" or just "048" or "48")
    final numberMatch = RegExp(r'(\d+)(?:/\d+)?$').firstMatch(searchTerm);
    
    if (numberMatch != null) {
      final number = numberMatch.group(1)!;
      final name = searchTerm.substring(0, numberMatch.start).trim();
      
      // For the Pokemon TCG API, we need to match the exact number format
      // Don't modify the number at all - use it exactly as provided
      if (name.isNotEmpty) {
        // If we have a name and number
        return {'q': 'name:"$name" number:"$number"'};
      } else {
        // Number only search - use exact number
        return {'q': 'number:"$number"'};
      }
    }
    
    // Name only search
    return {'q': 'name:"*$searchTerm*"'};
  }

  String? _getSetIdFromName(String query) {
    query = query.trim().toLowerCase();
    
    // First try direct match from setAliases
    if (setAliases.containsKey(query)) {
      return setAliases[query];
    }

    // Then try name variants
    for (final entry in setNameVariants.entries) {
      final variants = entry.value.map((v) => v.toLowerCase()).toList();
      if (variants.contains(query)) {
        return entry.key;
      }
    }

    // Finally try partial matches from setAliases
    for (final entry in setAliases.entries) {
      if (entry.key.contains(query) || query.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  static const Map<String, String> specialSearches = {
    'delta': 'nationalPokedexNumbers:[1 TO 999] subtypes:"delta species"',
    'delta species': 'nationalPokedexNumbers:[1 TO 999] subtypes:"delta species"',
    'ancient': 'subtypes:ancient',
    'trainer gallery': 'subtypes:"Trainer Gallery"',
    'gold': 'rarity:"Rare Secret"',
    'rainbow': 'rarity:"Rare Rainbow"',
  };

  String _processSearchQuery(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    
    // If query is already formatted, return as-is
    if (query.startsWith('set.id:') || 
        query.startsWith('name:') ||
        query.startsWith('subtypes:') ||
        query.startsWith('nationalPokedexNumbers:')) {
      return query;
    }

    // Check for special searches first
    if (specialSearches.containsKey(normalizedQuery)) {
      print('Found special search: ${specialSearches[normalizedQuery]}');
      return specialSearches[normalizedQuery]!;
    }

    // Try set match first
    String? setId = allSetIds[normalizedQuery];
    if (setId != null) {
      if (setId.startsWith('subtypes:')) {
        return setId;
      }
      print('Found exact set match: $setId for query: $query');
      return 'set.id:$setId';
    }

    // Try variations if no exact match
    if (setId == null) {
      final simplifiedQuery = normalizedQuery
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .replaceAll('and', '&');
          
      for (final entry in allSetIds.entries) {
        final simplifiedKey = entry.key
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '')
            .replaceAll('and', '&');
            
        if (simplifiedKey == simplifiedQuery ||
            simplifiedKey.contains(simplifiedQuery) ||
            simplifiedQuery.contains(simplifiedKey)) {
          setId = entry.value;
          break;
        }
      }
    }

    // Return set query if found
    if (setId != null) {
      if (setId.startsWith('subtypes:')) {
        return setId;
      }
      return 'set.id:$setId';
    }

    // Default to name search (but don't double wrap)
    print('No set match found, using name search for: $query');
    return 'name:*$query*';  // Simplified format without double quotes
  }

  static const Map<String, String> setQueries = {
    'furious fists': 'set.id:xy3',
    'breakpoint': 'set.id:xy9',
    'fates collide': 'set.id:xy10',
    'flashfire': 'set.id:xy2',
    'phantom forces': 'set.id:xy4',
    'roaring skies': 'set.id:xy6',
    'ancient origins': 'set.id:xy7',
    'breakthrough': 'set.id:xy8',
    'steam siege': 'set.id:xy11',
    'evolutions': 'set.id:xy12',
    // Add more mappings as needed
  };

  // Update searchCards to handle all sorting cases consistently
  Future<Map<String, dynamic>> searchCards({
    required String query,
    int page = 1,
    int pageSize = 30,
    String orderBy = 'cardmarket.prices.averageSellPrice',
    bool orderByDesc = true,
  }) async {
    try {
      final processedQuery = _processSearchQuery(query);
      print('Processing query: "$query" -> "$processedQuery"');

      final queryParams = {
        'q': processedQuery,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'orderBy': orderByDesc ? '-$orderBy' : orderBy,
        'select': 'id,name,number,images,set,rarity,subtypes,nationalPokedexNumber,cardmarket',
      };

      print('Making API request with query: $processedQuery');
      
      final response = await _dio.get('/cards', 
        queryParameters: queryParams,
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      
      if (response.statusCode == 400) {
        print('Search failed with invalid query: $processedQuery');
        // Try a simpler query format as fallback
        final fallbackQuery = query.startsWith('name:') ? query : 'name:*${query.trim()}*';
        return await _fallbackSearch(fallbackQuery, page, pageSize, orderBy, orderByDesc);
      }
      
      return {
        'data': response.data['data'] ?? [],
        'totalCount': response.data['totalCount'] ?? 0,
        'page': page,
      };

    } catch (e) {
      print('Search error: $e');
      return {'data': [], 'totalCount': 0, 'page': page};
    }
  }

  // Add this new method for fallback searches
  Future<Map<String, dynamic>> _fallbackSearch(
    String query,
    int page,
    int pageSize,
    String orderBy,
    bool orderByDesc,
  ) async {
    final queryParams = {
      'q': query,
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      'orderBy': orderByDesc ? '-$orderBy' : orderBy,
      'select': 'id,name,number,images,set,rarity,subtypes,nationalPokedexNumber,cardmarket',
    };

    print('Attempting fallback search with query: $query');
    
    final response = await _dio.get('/cards', 
      queryParameters: queryParams,
      options: Options(validateStatus: (status) => status != null && status < 500),
    );
    
    return {
      'data': response.data['data'] ?? [],
      'totalCount': response.data['totalCount'] ?? 0,
      'page': page,
    };
  }

  // Add helper method to safely extract price
  double _extractPrice(dynamic card) {
    try {
      final prices = card['cardmarket']?['prices'];
      if (prices == null) return 0.0;
      
      // Try market price first, then average sell price
      double? price = prices['averageSellPrice'];
      if (price == null) {
        price = prices['market'];
      }
      
      return price?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error extracting price: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>?> getCardDetails(String cardId) async {
    final url = Uri.parse('$_baseUrl/cards/$cardId');
    final response = await _client.get(url, headers: _headers);
    
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    return null;
  }

  String getEbaySearchUrl(String cardName, {String? setName}) {
    final searchTerms = [cardName, if (setName != null) setName, 'pokemon card'].join(' ');
    return 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(searchTerms)}';
  }

  Future<Map<String, dynamic>> _get(String endpoint, [Map<String, String>? queryParams]) async {
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers);
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<dynamic> _getWithCache(String endpoint) async {
    if (_cache.containsKey(endpoint)) {
      final (timestamp, data) = _cache[endpoint]!;
      if (DateTime.now().difference(timestamp) < _cacheDuration) {
        return data;
      }
    }
    
    final response = await _get(endpoint);
    _cache[endpoint] = (DateTime.now(), response);
    return response;
  }

  // Add this new method
  Future<Map<String, dynamic>> searchSet(String setId) async {
    try {
      final queryParams = {
        'q': 'set.id:$setId',
        'orderBy': '-cardmarket.prices.averageSellPrice',
        'pageSize': '60',  // Increased to show more cards
      };
      return await _get('cards', queryParams);
    } catch (e) {
      print('Set search error: $e');
      rethrow;
    }
  }
}
