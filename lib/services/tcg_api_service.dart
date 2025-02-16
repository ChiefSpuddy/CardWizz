import 'package:dio/dio.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tcg_card.dart';

// Move cache entry class outside
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  
  _CacheEntry(this.data) : timestamp = DateTime.now();
  
  bool get isExpired => 
    DateTime.now().difference(timestamp) > const Duration(hours: 1);
}

class TcgApiService {
  static const String apiKey = 'eebb53a0-319a-4231-9244-fd7ea48b5d2c';  // Add this line
  static final TcgApiService _instance = TcgApiService._internal();
  final Dio _dio;
  static const String _baseUrl = 'https://api.pokemontcg.io/v2';
  
  // Update rate limiting constants
  static const _requestDelay = Duration(milliseconds: 250); // Increased delay
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);
  static const _cacheExpiration = Duration(hours: 1);
  static const _maxConcurrentRequests = 2; // Reduce concurrent requests
  static const _rateLimitDelay = Duration(seconds: 5); // Add dedicated rate limit delay
  static const _imageCacheExpiration = Duration(days: 7); // Add image cache expiration
  
  final _requestQueue = <Future>[];
  final _cache = <String, _CacheEntry>{};
  final _imageCache = <String, String>{}; // Add image URL cache
  final _imageLoadErrors = <String>{}; // Track failed image URLs
  final _semaphore = Completer<void>()..complete();
  DateTime? _lastRequestTime;
  
  factory TcgApiService() => _instance;
  
  TcgApiService._internal() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {'X-Api-Key': apiKey},  // Now this will work
  ));

  // Add rate limiting method
  Future<void> _waitForRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _requestDelay) {
        await Future.delayed(_requestDelay - timeSinceLastRequest);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  // Basic sort options
  static const Map<String, String> sortOptions = {
    'number': 'Set Number',
    'name': 'Name',
    'cardmarket.prices.averageSellPrice': 'Price',
  };

  // Add dedicated set search method
  Future<Map<String, dynamic>> searchSets({
    required String query,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final searchQuery = query.isEmpty ? '' : 'name:"*${query.trim()}*"';
      
      print('Searching sets with query: $searchQuery');
      
      final response = await _dio.get('/sets', queryParameters: {
        if (searchQuery.isNotEmpty) 'q': searchQuery,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'orderBy': '-releaseDate', // Latest sets first
      });

      print('Found ${response.data['totalCount'] ?? 0} sets');
      return response.data;
    } catch (e) {
      print('Set search error: $e');
      return {'data': [], 'totalCount': 0, 'page': page};
    }
  }

  // Core search method - combining both implementations
  Future<Map<String, dynamic>> searchCards({
    required String query,
    String orderBy = 'number',
    bool orderByDesc = false,
    int pageSize = 20,
    int page = 1,
  }) async {
    final cacheKey = '$query-$orderBy-$orderByDesc-$pageSize-$page';
    
    // Check cache first
    final cacheEntry = _cache[cacheKey];
    if (cacheEntry != null && !cacheEntry.isExpired) {
      return cacheEntry.data as Map<String, dynamic>;
    }

    try {
      // If this is a set.id query, check if it needs special handling
      String cleanedQuery = query;
      if (query.startsWith('set.id:')) {
        final setId = query.replaceAll('set.id:', '').trim();
        cleanedQuery = _buildSpecialSetQuery(setId);
      } else {
        cleanedQuery = _cleanupQuery(query);
      }

      print('Searching with query: $cleanedQuery');

      final response = await _makeRequestWithRetry(
        '/cards',
        queryParameters: {
          'q': cleanedQuery,
          'orderBy': orderByDesc ? '-$orderBy' : orderBy,
          'pageSize': pageSize,
          'page': page,
        },
      );

      if (response['data'] != null) {
        // Convert the raw data to a format that matches our expected structure
        final result = {
          'data': response['data'],  // Keep as raw Map data
          'totalCount': response['totalCount'] ?? 0,
          'page': page,
        };

        _cache[cacheKey] = _CacheEntry(result);
        return result;
      }

      return {'data': [], 'totalCount': 0, 'page': page};

    } catch (e) {
      print('Search error: $e');
      rethrow;
    }
  }

  // Add batch search method
  Future<List<Map<String, dynamic>>> searchCardsBatch(
    List<String> queries,
  ) async {
    final results = <Map<String, dynamic>>[];
    final batch = <Future<Map<String, dynamic>>>[];

    for (final query in queries) {
      // Check cache first
      final cacheKey = '$query-number-false-1-1';
      final cacheEntry = _cache[cacheKey];
      
      if (cacheEntry != null && !cacheEntry.isExpired) {
        results.add(cacheEntry.data as Map<String, dynamic>);
        continue;
      }

      // Add to batch if not cached
      batch.add(searchCards(query: query, pageSize: 1));
      
      // Process batch when full
      if (batch.length >= _maxConcurrentRequests) {
        results.addAll(await Future.wait(batch));
        batch.clear();
        await Future.delayed(_requestDelay);
      }
    }

    // Process remaining requests
    if (batch.isNotEmpty) {
      results.addAll(await Future.wait(batch));
    }

    return results;
  }

  String _cleanupQuery(String query) {
    // Don't modify set.id queries
    if (query.startsWith('set.id:')) {
      return query;
    }

    // Special query handlers
    if (query.startsWith('rarity:') || query.startsWith('subtypes:')) {
      return query;
    }

    // Clean the query
    String clean = query
      .toLowerCase()
      .trim()
      .replaceAll('"', '')
      .replaceAll('\'', '')
      .replaceAll('♀', 'f')
      .replaceAll('♂', 'm');

    // Handle special cases
    if (clean.contains('nidoran')) {
      if (clean.contains('m') || clean.contains('M')) {
        return 'name:"Nidoran ♂"';
      } else if (clean.contains('f') || clean.contains('F')) {
        return 'name:"Nidoran ♀"';
      }
    }

    // If it's not a special query, wrap in name search
    if (!clean.contains(':')) {
      return 'name:"$clean"';
    }

    return clean;
  }

  Future<Map<String, dynamic>> _makeRequestWithRetry(
    String path, {
    Map<String, dynamic>? queryParameters,
    int retryCount = 0,
  }) async {
    try {
      // Add delay between requests
      await _waitForRateLimit();
      
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 429) {
          if (retryCount < _maxRetries) {
            print('Rate limited, waiting ${_rateLimitDelay.inSeconds}s before retry...');
            await Future.delayed(_rateLimitDelay * (retryCount + 1));
            return _makeRequestWithRetry(
              path,
              queryParameters: queryParameters,
              retryCount: retryCount + 1,
            );
          }
        } else if (e.response?.statusCode == 404) {
          // Handle 404 errors for images
          final url = e.requestOptions.uri.toString();
          if (url.contains('/images/')) {
            _imageLoadErrors.add(url);
            return {'data': []};
          }
        }
      }
      rethrow;
    }
  }

  // Add method to validate image URL
  String? getValidImageUrl(String? url) {
    if (url == null || _imageLoadErrors.contains(url)) {
      return null;
    }
    return _imageCache[url] ?? url;
  }

  void _cleanCache() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  // Clear cache method
  void clearCache() {
    _cache.clear();
  }

  // Get single card details
  Future<Map<String, dynamic>?> getCardDetails(String cardId) async {
    try {
      final response = await _dio.get('/cards/$cardId');
      return response.data['data'];
    } catch (e) {
      print('Error getting card details: $e');
      return null;
    }
  }

  // Update searchSet to handle pagination - removing duplicate implementation
  Future<Map<String, dynamic>> searchSet(
    String setId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return searchCards(
      query: 'set.id:$setId',
      orderBy: 'number',
      orderByDesc: false,
      page: page,
      pageSize: pageSize,
    );
  }

  // Helper for eBay links
  String getEbaySearchUrl(String cardName, {String? setName}) {
    final terms = [cardName, if (setName != null) setName, 'pokemon card']
      .join(' ');
    return 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(terms)}';
  }

  // Add helper method to get set logo
  String getSetLogo(String setQuery) {
    // Extract set ID from query
    final setId = setQuery.replaceAll('set.id:', '').trim();
    return _setLogos[setId] ?? _defaultSetLogo;
  }

  static const _defaultSetLogo = 'https://images.pokemontcg.io/logos/default.png';

  // Updated set logo map with actual URLs
  static const _setLogos = {
    // Latest Scarlet & Violet
    'sv8pt5': 'https://images.pokemontcg.io/sv8pt5/logo.png', // Prismatic Evolution
    'sv8': 'https://images.pokemontcg.io/sv8/logo.png',       // Surging Sparks
    'sv9pt5': 'https://images.pokemontcg.io/sv9pt5/logo.png', // Twilight Masquerade
    'sv9': 'https://images.pokemontcg.io/sv9/logo.png',       // Stellar Crown
    'sv5': 'https://images.pokemontcg.io/sv5/logo.png',       // Temporal Forces
    'sv4': 'https://images.pokemontcg.io/sv4/logo.png',       // Paradox Rift
    'sv3pt5': 'https://images.pokemontcg.io/sv3pt5/logo.png', // 151
    'sv3': 'https://images.pokemontcg.io/sv3/logo.png',       // Obsidian Flames
    'sv2': 'https://images.pokemontcg.io/sv2/logo.png',       // Paldea Evolved
    'sv1': 'https://images.pokemontcg.io/sv1/logo.png',       // Scarlet & Violet Base

    // Sword & Shield Era
    'swsh12pt5': 'https://images.pokemontcg.io/swsh12pt5/logo.png',
    'swsh12': 'https://images.pokemontcg.io/swsh12/logo.png',
    'swsh11': 'https://images.pokemontcg.io/swsh11/logo.png',
    'swsh10': 'https://images.pokemontcg.io/swsh10/logo.png',
    'swsh9': 'https://images.pokemontcg.io/swsh9/logo.png',
    'swsh8': 'https://images.pokemontcg.io/swsh8/logo.png',
    'swsh7': 'https://images.pokemontcg.io/swsh7/logo.png',
    'swsh6': 'https://images.pokemontcg.io/swsh6/logo.png',
    'swsh5': 'https://images.pokemontcg.io/swsh5/logo.png',
    'swsh45': 'https://images.pokemontcg.io/swsh45/logo.png',
    'swsh4': 'https://images.pokemontcg.io/swsh4/logo.png',
    'swsh3': 'https://images.pokemontcg.io/swsh3/logo.png',
    'swsh2': 'https://images.pokemontcg.io/swsh2/logo.png',
    'swsh35': 'https://images.pokemontcg.io/swsh35/logo.png',
    'swsh1': 'https://images.pokemontcg.io/swsh1/logo.png',

    // Sun & Moon Era
    'sm12': 'https://images.pokemontcg.io/sm12/logo.png',    // Cosmic Eclipse
    'sm11': 'https://images.pokemontcg.io/sm11/logo.png',    // Unified Minds
    'sm10': 'https://images.pokemontcg.io/sm10/logo.png',    // Unbroken Bonds
    'sm9': 'https://images.pokemontcg.io/sm9/logo.png',      // Team Up
    'sm8': 'https://images.pokemontcg.io/sm8/logo.png',      // Lost Thunder
    'sm7': 'https://images.pokemontcg.io/sm7/logo.png',      // Celestial Storm
    'sm6': 'https://images.pokemontcg.io/sm6/logo.png',      // Forbidden Light
    'sm5': 'https://images.pokemontcg.io/sm5/logo.png',      // Ultra Prism
    'sm4': 'https://images.pokemontcg.io/sm4/logo.png',      // Crimson Invasion
    'sm3': 'https://images.pokemontcg.io/sm3/logo.png',      // Burning Shadows
    'sm2': 'https://images.pokemontcg.io/sm2/logo.png',      // Guardians Rising
    'sm1': 'https://images.pokemontcg.io/sm1/logo.png',      // Sun & Moon Base
    'sm115': 'https://images.pokemontcg.io/sm115/logo.png',  // Hidden Fates
    'sm35': 'https://images.pokemontcg.io/sm35/logo.png',    // Shining Legends

    // XY Era
    'xy12': 'https://images.pokemontcg.io/xy12/logo.png',    // Evolutions
    'xy11': 'https://images.pokemontcg.io/xy11/logo.png',    // Steam Siege
    'xy10': 'https://images.pokemontcg.io/xy10/logo.png',    // Fates Collide
    'xy9': 'https://images.pokemontcg.io/xy9/logo.png',      // BREAKpoint
    'xy8': 'https://images.pokemontcg.io/xy8/logo.png',      // BREAKthrough
    'xy7': 'https://images.pokemontcg.io/xy7/logo.png',      // Ancient Origins
    'xy6': 'https://images.pokemontcg.io/xy6/logo.png',      // Roaring Skies
    'xy5': 'https://images.pokemontcg.io/xy5/logo.png',      // Primal Clash
    'xy4': 'https://images.pokemontcg.io/xy4/logo.png',      // Phantom Forces
    'xy3': 'https://images.pokemontcg.io/xy3/logo.png',      // Furious Fists
    'xy2': 'https://images.pokemontcg.io/xy2/logo.png',      // Flashfire
    'xy1': 'https://images.pokemontcg.io/xy1/logo.png',      // XY Base Set
    'g1': 'https://images.pokemontcg.io/g1/logo.png',        // Generations

    // Black & White Era
    'bw11': 'https://images.pokemontcg.io/bw11/logo.png',    // Legendary Treasures
    'bw10': 'https://images.pokemontcg.io/bw10/logo.png',    // Plasma Blast
    'bw9': 'https://images.pokemontcg.io/bw9/logo.png',      // Plasma Freeze
    'bw8': 'https://images.pokemontcg.io/bw8/logo.png',      // Plasma Storm
    'bw7': 'https://images.pokemontcg.io/bw7/logo.png',      // Boundaries Crossed
    'bw6': 'https://images.pokemontcg.io/bw6/logo.png',      // Dragons Exalted
    'bw5': 'https://images.pokemontcg.io/bw5/logo.png',      // Dark Explorers
    'bw4': 'https://images.pokemontcg.io/bw4/logo.png',      // Next Destinies
    'bw3': 'https://images.pokemontcg.io/bw3/logo.png',      // Noble Victories
    'bw2': 'https://images.pokemontcg.io/bw2/logo.png',      // Emerging Powers
    'bw1': 'https://images.pokemontcg.io/bw1/logo.png',      // Black & White Base

    // HeartGold SoulSilver Era
    'hgss4': 'https://images.pokemontcg.io/hgss4/logo.png',  // Triumphant
    'hgss3': 'https://images.pokemontcg.io/hgss3/logo.png',  // Undaunted
    'hgss2': 'https://images.pokemontcg.io/hgss2/logo.png',  // Unleashed
    'hgss1': 'https://images.pokemontcg.io/hgss1/logo.png',  // HGSS Base Set
    'col1': 'https://images.pokemontcg.io/col1/logo.png',    // Call of Legends

    // Diamond & Pearl Era
    'pl4': 'https://images.pokemontcg.io/pl4/logo.png',      // Arceus
    'pl3': 'https://images.pokemontcg.io/pl3/logo.png',      // Supreme Victors
    'pl2': 'https://images.pokemontcg.io/pl2/logo.png',      // Rising Rivals
    'pl1': 'https://images.pokemontcg.io/pl1/logo.png',      // Platinum Base
    'dp7': 'https://images.pokemontcg.io/dp7/logo.png',      // Stormfront
    'dp6': 'https://images.pokemontcg.io/dp6/logo.png',      // Legends Awakened
    'dp5': 'https://images.pokemontcg.io/dp5/logo.png',      // Majestic Dawn
    'dp4': 'https://images.pokemontcg.io/dp4/logo.png',      // Great Encounters
    'dp3': 'https://images.pokemontcg.io/dp3/logo.png',      // Secret Wonders
    'dp2': 'https://images.pokemontcg.io/dp2/logo.png',      // Mysterious Treasures
    'dp1': 'https://images.pokemontcg.io/dp1/logo.png',      // Diamond & Pearl Base

    // EX Era
    'ex16': 'https://images.pokemontcg.io/ex16/logo.png',    // Power Keepers
    'ex15': 'https://images.pokemontcg.io/ex15/logo.png',    // Dragon Frontiers
    'ex14': 'https://images.pokemontcg.io/ex14/logo.png',    // Crystal Guardians
    'ex13': 'https://images.pokemontcg.io/ex13/logo.png',    // Holon Phantoms
    'ex12': 'https://images.pokemontcg.io/ex12/logo.png',    // Legend Maker
    'ex11': 'https://images.pokemontcg.io/ex11/logo.png',    // Delta Species
    'ex10': 'https://images.pokemontcg.io/ex10/logo.png',    // Unseen Forces
    'ex9': 'https://images.pokemontcg.io/ex9/logo.png',      // Emerald
    'ex8': 'https://images.pokemontcg.io/ex8/logo.png',      // Deoxys
    'ex7': 'https://images.pokemontcg.io/ex7/logo.png',      // Team Rocket Returns
    'ex6': 'https://images.pokemontcg.io/ex6/logo.png',      // FireRed & LeafGreen
    'ex5': 'https://images.pokemontcg.io/ex5/logo.png',      // Hidden Legends
    'ex4': 'https://images.pokemontcg.io/ex4/logo.png',      // Team Magma vs Team Aqua
    'ex3': 'https://images.pokemontcg.io/ex3/logo.png',      // Dragon
    'ex2': 'https://images.pokemontcg.io/ex2/logo.png',      // Sandstorm
    'ex1': 'https://images.pokemontcg.io/ex1/logo.png',      // Ruby & Sapphire

    // Classic Sets
    'base1': 'https://images.pokemontcg.io/base1/logo.png',  // Base Set
    'base2': 'https://images.pokemontcg.io/base2/logo.png',  // Jungle
    'base3': 'https://images.pokemontcg.io/base3/logo.png',  // Fossil
    'base4': 'https://images.pokemontcg.io/base4/logo.png',  // Base Set 2
    'base5': 'https://images.pokemontcg.io/base5/logo.png',  // Team Rocket
    'base6': 'https://images.pokemontcg.io/base6/logo.png',  // Legendary Collection
    'gym1': 'https://images.pokemontcg.io/gym1/logo.png',    // Gym Heroes
    'gym2': 'https://images.pokemontcg.io/gym2/logo.png',    // Gym Challenge
    'neo1': 'https://images.pokemontcg.io/neo1/logo.png',    // Neo Genesis
    'neo2': 'https://images.pokemontcg.io/neo2/logo.png',    // Neo Discovery
    'neo3': 'https://images.pokemontcg.io/neo3/logo.png',    // Neo Revelation
    'neo4': 'https://images.pokemontcg.io/neo4/logo.png',    // Neo Destiny
    'si1': 'https://images.pokemontcg.io/si1/logo.png',      // Southern Islands
    'ecard1': 'https://images.pokemontcg.io/ecard1/logo.png', // Expedition Base Set
    'ecard2': 'https://images.pokemontcg.io/ecard2/logo.png', // Aquapolis
    'ecard3': 'https://images.pokemontcg.io/ecard3/logo.png', // Skyridge
  };

  // Add this method near the getCardPrice and searchCards methods
  Future<Map<String, dynamic>?> getCardById(String cardId) async {
    try {
      final cacheKey = 'card_$cardId';
      
      // Check cache first
      final cacheEntry = _cache[cacheKey];
      if (cacheEntry != null && !cacheEntry.isExpired) {
        return cacheEntry.data as Map<String, dynamic>;
      }

      await _waitForRateLimit();
      final response = await _dio.get('/cards/$cardId');
      final data = response.data['data'] as Map<String, dynamic>;
      
      // Cache the response
      _cache[cacheKey] = _CacheEntry(data);
      
      return data;
    } catch (e) {
      print('Error getting card by ID: $e');
      return null;
    }
  }

  // Add this method
  Future<double?> getCardPrice(String cardId) async {
    try {
      final data = await getCardById(cardId);
      return data?['cardmarket']?['prices']?['averageSellPrice'] as double?;
    } catch (e) {
      print('Error getting card price: $e');
      return null;
    }
  }

  Future<double?> fetchCardPrice(String cardId) async {
    try {
      print('🔍 Fetching price for card $cardId');
      final response = await _makeRequestWithRetry('/cards/$cardId');
      
      if (response == null) {
        print('❌ No response for card $cardId');
        return null;
      }

      final price = response['data']?['cardmarket']?['prices']?['averageSellPrice'];
      if (price != null) {
        print('✅ Found price $price for card $cardId');
        return (price as num).toDouble();
      } else {
        print('❌ No price data found for card $cardId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching card price: $e');
      return null;
    }
  }

  TcgCard _convertToTcgCard(Map<String, dynamic> data) {
    return TcgCard(
      id: data['id'] as String,
      name: data['name'] as String,
      number: data['number']?.toString() ?? '',
      rarity: data['rarity'] as String?,
      imageUrl: data['images']?['small'] as String? ?? '',
      largeImageUrl: data['images']?['large'] as String? ?? '',
      price: data['cardmarket']?['prices']?['averageSellPrice'] as double?,
      set: data['set'] != null ? TcgSet(
        id: data['set']['id'] as String,
        name: data['set']['name'] as String,
        series: data['set']['series'] as String,
        total: data['set']['total'] as int,
      ) : null,
    );
  }

  // Add new method to get most valuable cards
  Future<Map<String, dynamic>> searchMostValuableCards() async {
    final params = {
      'page': '1',
      'pageSize': '250',
      'orderBy': 'cardmarket.prices.avg1',
      'desc': 'true',
      'q': 'cardmarket.prices.avg1:exists' // Only get cards with prices
    };

    final response = await _makeRequest('cards', params);
    return jsonDecode(response.body);
  }

  // Fix the _makeRequest method
  Future<http.Response> _makeRequest(String endpoint, Map<String, dynamic> params) async {
    await _waitForRateLimit();
    
    // Fix the URL construction
    final uri = Uri.parse('https://api.pokemontcg.io/v2/$endpoint').replace(
      queryParameters: params.map((key, value) => MapEntry(key, value.toString())),
    );
    
    try {
      final response = await http.get(
        uri,
        headers: {'X-Api-Key': apiKey},
      );

      if (response.statusCode == 429) {
        await Future.delayed(_rateLimitDelay);
        return _makeRequest(endpoint, params);
      }

      return response;
    } catch (e) {
      print('API request failed: $e');
      rethrow;
    }
  }

  String _buildSpecialSetQuery(String setId) {
    // Special handling for sets with subsets
    switch (setId) {
      case 'swsh12pt5': // Crown Zenith
        return 'set.id:swsh12pt5 OR set.id:swsh12pt5gg'; // Include Galarian Gallery
      case 'swsh11': // Lost Origin
        return 'set.id:swsh11 OR set.id:swsh11tg'; // Include Trainer Gallery
      case 'swsh10': // Astral Radiance
        return 'set.id:swsh10 OR set.id:swsh10tg'; // Include Trainer Gallery
      case 'swsh9': // Brilliant Stars
        return 'set.id:swsh9 OR set.id:swsh9tg'; // Include Trainer Gallery
      default:
        return 'set.id:$setId';
    }
  }
}
