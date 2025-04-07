import '../services/logging_service.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './tcgdex_api_service.dart';
import '../models/tcg_card.dart';
import '../models/tcg_set.dart' as models; // Direct import, not aliased
import '../utils/cache_manager.dart';

// Cache entry class
class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  
  _CacheEntry(this.data) : timestamp = DateTime.now();
  
  bool get isExpired => 
    DateTime.now().difference(timestamp) > const Duration(hours: 1);
}

class TcgApiService {
  static const String apiKey = 'eebb53a0-319a-4231-9244-fd7ea48b5d2c';
  static final TcgApiService _instance = TcgApiService._internal();
  final Dio _dio;
  static const String _baseUrl = 'https://api.pokemontcg.io/v2';
  
  // Add this line to define the _headers field
  final Map<String, String> _headers = {'X-Api-Key': apiKey};
  
  // Rate limiting constants
  static const _requestDelay = Duration(milliseconds: 250);
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);
  static const _cacheExpiration = Duration(hours: 1);
  static const _maxConcurrentRequests = 2;
  static const _rateLimitDelay = Duration(seconds: 5);
  static const _imageCacheExpiration = Duration(days: 7);
  
  final _requestQueue = <Future>[];
  final _cache = <String, _CacheEntry>{};
  final _imageCache = <String, String>{};
  final _imageLoadErrors = <String>{};
  final _semaphore = Completer<void>()..complete();
  DateTime? _lastRequestTime;
  
  factory TcgApiService() => _instance;
  
  TcgApiService._internal() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {'X-Api-Key': apiKey},
  ));

  final _tcgdexApi = TcgdexApiService();
  final _cacheManager = CustomCacheManager();
  
  // Configure cache durations based on search type
  static const Duration _normalSearchCacheDuration = Duration(hours: 1);  // Cache normal searches for 1 hour
  static const Duration _setSearchCacheDuration = Duration(hours: 24);    // Cache set searches for 24 hours

  // Rate limiting method
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

  // Set search method
  Future<Map<String, dynamic>> searchSets({
    required String query,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      // Clean the query for better matching
      final String normalizedQuery = query.trim().toLowerCase();
      
      // Log the search attempt
      LoggingService.debug('Searching sets with query: $normalizedQuery');
      
      // Prepare API parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'orderBy': '-releaseDate', // Latest sets first
      };
      
      // Only add name filter if query is not empty
      if (normalizedQuery.isNotEmpty) {
        queryParams['q'] = 'name:"*$normalizedQuery*"';
      }
      
      final response = await _dio.get('/sets', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Debug logging
        LoggingService.debug('Found ${data['totalCount'] ?? 0} sets');
        
        // If we have data, log the first set for debugging
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          LoggingService.debug('First set: ${(data['data'] as List)[0]['name']}');
        }
        
        return data;
      } else {
        LoggingService.debug('Set search failed: ${response.statusCode}');
        return {'data': [], 'totalCount': 0, 'page': page};
      }
    } catch (e) {
      LoggingService.debug('Set search error: $e');
      return {'data': [], 'totalCount': 0, 'page': page};
    }
  }
  
  // Get single set details
  Future<Map<String, dynamic>?> getSetDetails(String setId) async {
    try {
      final cacheKey = 'set_$setId';
      
      // Check cache first
      final cacheEntry = _cache[cacheKey];
      if (cacheEntry != null && !cacheEntry.isExpired) {
        return cacheEntry.data as Map<String, dynamic>;
      }

      await _waitForRateLimit();
      final response = await _dio.get('/sets/$setId');
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        
        // Cache the response
        _cache[cacheKey] = _CacheEntry(data);
        
        return data;
      } else {
        LoggingService.debug('Failed to get set details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggingService.debug('Error getting set details: $e');
      return null;
    }
  }

  // Core search method
  Future<Map<String, dynamic>> searchCards({
    required String query,
    String orderBy = 'number',
    bool orderByDesc = false,
    int pageSize = 20,
    int page = 1,
    bool useCache = true,
  }) async {
    final cacheKey = '$query-$orderBy-$orderByDesc-$pageSize-$page';
    
    // Check cache first
    final cacheEntry = _cache[cacheKey];
    if (cacheEntry != null && !cacheEntry.isExpired) {
      return cacheEntry.data as Map<String, dynamic>;
    }

    // Check if this is a Japanese set query
    if (query.startsWith('set.id:') && query.contains('-jp')) {
      final setId = query.replaceAll('set.id:', '').trim();
      return _tcgdexApi.searchJapaneseSet(setId);
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

      LoggingService.debug('Searching with query: $cleanedQuery');

      // IMPORTANT: First debug print to see the API request
      final request = {
        'q': cleanedQuery,
        'orderBy': orderByDesc ? '-$orderBy' : orderBy,
        'pageSize': pageSize,
        'page': page,
        // IMPORTANT: Make sure we're requesting images
        'select': 'id,name,number,rarity,images,cardmarket,set',
      };
      
      LoggingService.debug('API Request params: $request');

      final response = await _makeRequestWithRetry(
        '/cards',
        queryParameters: request,
      );

      // IMPORTANT: Log the first card to see its structure
      if (response['data'] != null && (response['data'] as List).isNotEmpty) {
        LoggingService.debug('First card sample: ${response['data'][0]}');
        final firstCard = response['data'][0];
        print('First card name: ${firstCard['name']}, images: ${firstCard['images']}');
      }

      if (response['data'] != null) {
        // Process the data and manually ensure images are extracted properly
        final processedData = response['data'].map((card) {
          // IMPORTANT: Make sure image URLs are explicitly copied to prevent loss
          final cardWithImages = <String, dynamic>{...card};
          
          // Log the image data for the first card
          if (card == response['data'][0]) {
            print('Processing first card: ${card['name']}');
            print('Image data: ${card['images']}');
          }
          
          // Process pricing data
          if (card['cardmarket'] != null) {
            final prices = card['cardmarket']['prices'];
            if (prices != null) {
              prices['averageSellPrice'] = _toDouble(prices['averageSellPrice']);
              prices['lowPrice'] = _toDouble(prices['lowPrice']);
              prices['trendPrice'] = _toDouble(prices['trendPrice']);
            }
          }
          
          return cardWithImages;
        }).toList();

        // Cache this result
        final resultData = {
          'data': processedData,
          'totalCount': response['totalCount'] ?? 0,
          'page': page,
        };
        
        _cache[cacheKey] = _CacheEntry(resultData);
        return resultData;
      }

      return {'data': [], 'totalCount': 0, 'page': page};

    } catch (e) {
      LoggingService.debug('Search error: $e');
      rethrow;
    }
  }

  // Batch search method
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
            LoggingService.debug('Rate limited, waiting ${_rateLimitDelay.inSeconds}s before retry...');
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

  // Method to validate image URL
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
  Future<Map<String, dynamic>> getCardDetails(String cardId) async {
    try {
      if (cardId.startsWith("mtg_")) {
        // This is an MTG card - use Scryfall API directly with the UUID
        String scryId = cardId.replaceAll("mtg_", "");
        final url = 'https://api.scryfall.com/cards/$scryId';
        LoggingService.debug('Fetching MTG card details: $url');
        
        final response = await _dio.get(url);
        if (response.statusCode == 200) {
          return response.data;
        } else {
          LoggingService.debug('Error fetching MTG card details: ${response.statusCode}');
          return {};
        }
      } else {
        // Use original implementation for Pokemon cards
        final url = '${_baseUrl}/cards/$cardId';
        final response = await _dio.get(url);
        if (response.statusCode == 200) {
          return response.data;
        } else {
          throw Exception('Failed to load card details');
        }
      }
    } catch (e) {
      LoggingService.debug('Error getting card details: $e');
      return {};
    }
  }

  // Method to get Scryfall data directly by set and collector number
  Future<Map<String, dynamic>> getScryfallCardBySetAndNumber(
      String setCode, String number) async {
    try {
      if (setCode.isEmpty) throw Exception('Empty set code');
      if (number.isEmpty) throw Exception('Empty collector number');
      
      // Normalize the set code and number
      final normalizedSetCode = setCode.trim().toLowerCase();
      final normalizedNumber = number.trim();
      
      // Log the request
      LoggingService.debug('Fetching MTG card details: https://api.scryfall.com/cards/$normalizedSetCode/$normalizedNumber');
      
      // Make the API request
      final response = await _dio.get(
        'https://api.scryfall.com/cards/$normalizedSetCode/$normalizedNumber',
      );
      
      // Check the response
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load card details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.debug('Error getting MTG card details: $e');
      throw Exception('Failed to retrieve card details: $e');
    }
  }

  // Helper method for MTG eBay URLs
  String getEbayMtgSearchUrl(String cardName, {String? setName, String? number}) {
    // Normalize inputs
    final normalizedCardName = cardName.trim();
    final setNameQuery = setName != null && setName.trim().isNotEmpty 
      ? ' "${setName.trim()}"' : '';
    final numberQuery = number != null && number.trim().isNotEmpty
      ? ' $number' : '';
    
    // Create the search query
    final query = Uri.encodeComponent(
      '$normalizedCardName MTG$setNameQuery$numberQuery'
    );
    
    // Log URL for debugging
    final url = 'https://www.ebay.com/sch/i.html?_nkw=$query&_sacat=2536&LH_Sold=1&LH_Complete=1&_sop=13';
    LoggingService.debug('eBay search URL: $url');
    
    return url;
  }

  // Search set pagination handler - modify to accept orderBy and orderByDesc
  Future<Map<String, dynamic>> searchSet(
    String setId, {
    int page = 1,
    int pageSize = 20,
    String? orderBy,
    bool orderByDesc = false,
  }) async {
    // Construct the query with ordering if specified
    String query = 'set.id:$setId';
    
    return searchCards(
      query: query,
      orderBy: orderBy ?? 'number',
      orderByDesc: orderByDesc,
      page: page,
      pageSize: pageSize,
    );
  }

  // Helper for Pokemon eBay links
  String getEbaySearchUrl(String cardName, {String? setName, String? number}) {
    // Normalize inputs 
    final normalizedCardName = cardName.trim();
    final setNameQuery = setName != null && setName.trim().isNotEmpty 
      ? ' "${setName.trim()}"' : '';
    final numberQuery = number != null && number.trim().isNotEmpty
      ? ' $number' : '';
    
    // Create the search query
    final query = Uri.encodeComponent(
      '$normalizedCardName pokemon card$setNameQuery$numberQuery'
    );
    
    // Log URL for debugging
    final url = 'https://www.ebay.com/sch/i.html?_nkw=$query&_sacat=183454&LH_Sold=1&LH_Complete=1&_sop=13';
    LoggingService.debug('eBay search URL: $url');
    
    return url;
  }

  // Helper method to get set logo
  String getSetLogo(String setQuery) {
    // Extract set ID from query
    final setId = setQuery.replaceAll('set.id:', '').trim();
    return _setLogos[setId] ?? _defaultSetLogo;
  }

  static const _defaultSetLogo = 'https://images.pokemontcg.io/logos/default.png';

  // Set logos map with actual URLs
  static const _setLogos = {
    // Latest Scarlet & Violet
    'sv9': 'https://images.pokemontcg.io/sv9/logo.png',       // Journey Together - ADD THIS LINE
    'sv8pt5': 'https://images.pokemontcg.io/sv8pt5/logo.png', // Prismatic Evolution
    'sv8': 'https://images.pokemontcg.io/sv8/logo.png',       // Surging Sparks
    'sv9pt5': 'https://images.pokemontcg.io/sv9pt5/logo.png', // Twilight Masquerade
    'sv5': 'https://images.pokemontcg.io/sv5/logo.png',       // Temporal Forces
    'sv4pt5': 'https://images.pokemontcg.io/sv4pt5/logo.png', // Paldean Fates
    'sv4': 'https://images.pokemontcg.io/sv4/logo.png',       // Paradox Rift
    'sv3pt5': 'https://images.pokemontcg.io/sv3pt5/logo.png', // 151
    'sv3': 'https://images.pokemontcg.io/sv3/logo.png',       // Obsidian Flames
    'sv2': 'https://images.pokemontcg.io/sv2/logo.png',       // Paldea Evolved
    'sv1': 'https://images.pokemontcg.io/sv1/logo.png',       // Scarlet & Violet Base

    // Sword & Shield Era through Classic Sets
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
    'sm75': 'https://images.pokemontcg.io/sm75/logo.png',    // Dragon Majesty

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

    // Promo Sets
    'swshp': 'https://images.pokemontcg.io/swshp/logo.png',    // SWSH Black Star Promos
    'smp': 'https://images.pokemontcg.io/smp/logo.png',        // SM Black Star Promos
    'xyp': 'https://images.pokemontcg.io/xyp/logo.png',        // XY Black Star Promos
    'bwp': 'https://images.pokemontcg.io/bwp/logo.png',        // BW Black Star Promos
  };

  // Method to get card by ID
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
      LoggingService.debug('Error getting card by ID: $e');
      return null;
    }
  }

  // Add this method
  Future<double?> getCardPrice(String cardId) async {
    try {
      final data = await getCardById(cardId);
      return data?['cardmarket']?['prices']?['averageSellPrice'] as double?;
    } catch (e) {
      LoggingService.debug('Error getting card price: $e');
      return null;
    }
  }

  Future<double?> fetchCardPrice(String cardId) async {
    try {
      LoggingService.debug('🔍 Fetching price for card $cardId');
      final response = await _makeRequestWithRetry('/cards/$cardId');
      
      if (response == null) {
        LoggingService.debug('❌ No response for card $cardId');
        return null;
      }

      final price = response['data']?['cardmarket']?['prices']?['averageSellPrice'];
      if (price != null) {
        LoggingService.debug('✅ Found price $price for card $cardId');
        return (price as num).toDouble();
      } else {
        LoggingService.debug('❌ No price data found for card $cardId');
        return null;
      }
    } catch (e) {
      LoggingService.debug('❌ Error fetching card price: $e');
      return null;
    }
  }

  // Modify the _convertToTcgCard method with better price extraction
TcgCard _convertToTcgCard(Map<String, dynamic> data) {
  // Create the set object
  final set = models.TcgSet(
    id: data['set']?['id'] ?? '',
    name: data['set']?['name'] ?? '',
    symbol: data['set']?['images']?['symbol'],
    releaseDate: data['set']?['releaseDate'],
    printedTotal: data['set']?['printedTotal'],
    total: data['set']?['total'],
  );
  
  // IMPORTANT: Extract the image URLs correctly from the data
  String? imageUrl;
  String? largeImageUrl;
  
  // Check the 'images' node which contains the card images
  if (data['images'] != null) {
    imageUrl = data['images']['small'];
    largeImageUrl = data['images']['large'];
    
    // Fix URL format if needed
    if (imageUrl != null && imageUrl.startsWith('//')) {
      imageUrl = 'https:$imageUrl';
    }
    
    if (largeImageUrl != null && largeImageUrl.startsWith('//')) {
      largeImageUrl = 'https:$largeImageUrl';
    }
  }
  
  // Extract price data more carefully
  double? price;
  if (data['cardmarket'] != null && data['cardmarket']['prices'] != null) {
    final prices = data['cardmarket']['prices'];
    price = _toDouble(prices['averageSellPrice']);
    if (price == null || price == 0) {
      // Try other price fields if averageSellPrice is missing
      price = _toDouble(prices['trendPrice']) ?? 
              _toDouble(prices['lowPrice']) ?? 
              _toDouble(prices['avg1']) ??
              _toDouble(prices['avg7']) ??
              _toDouble(prices['avg30']);
    }
  }

  print('Card: ${data['name']}, Image URL: $imageUrl, Price: $price');
  
  // Return the card with properly extracted image URLs and price
  return TcgCard(
    id: data['id'] ?? '',
    name: data['name'] ?? '',
    number: data['number']?.toString(),
    imageUrl: imageUrl,
    largeImageUrl: largeImageUrl,
    set: set,
    rarity: data['rarity']?.toString(),
    setName: data['set']?['name'],
    price: price, // Use the extracted price
    cardmarket: data['cardmarket'], // Store the full cardmarket data
    rawData: data, // Store the complete raw data for future reference
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
      LoggingService.debug('API request failed: $e');
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

  Future<Map<String, dynamic>> getSets() async {
    final response = await _dio.get('/sets');
    return response.data;
  }

  // Add this helper method
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Add a new method to fetch all available rarities
  Future<List<String>> getRarities() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.pokemontcg.io/v2/rarities'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rarities = data['data'];
        return rarities.map((r) => r.toString()).toList();
      } else {
        throw Exception('Failed to load rarities: ${response.statusCode}');
      }
    } catch (e) {
      LoggingService.debug('Error fetching rarities: $e');
      return [];
    }
  }

  // Method to search sets by name - uses the /sets endpoint directly
  Future<Map<String, dynamic>> searchSetsByName(String setName, {bool useCache = true}) async {
    try {
      LoggingService.debug('Searching for set with name: $setName');
      
      final queryParams = <String, String>{
        'q': 'name:"*$setName*"', // Use wildcard search to match partial names
        'orderBy': 'releaseDate',  // Sort by release date
        'page': '1',
        'pageSize': '250',         // Get all sets in one request
      };
      
      final cacheKey = _createCacheKey('/sets', queryParams);
      
      // Try to get from cache first
      if (useCache) {
        final cachedResult = await _cacheManager.get(cacheKey);
        if (cachedResult != null) {
          LoggingService.debug('Retrieved set search results from cache for: $setName');
          return cachedResult;
        }
      }
      
      // No cache hit, perform actual API request
      final response = await _dio.get('/sets', queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.data;
        LoggingService.debug('Found ${data['count']} sets matching "$setName"');
        
        // If the set is found, log the first match
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          final firstSet = (data['data'] as List)[0];
          LoggingService.debug('First matching set: ${firstSet['name']} (${firstSet['id']})');
        }
        
        // Cache this result for longer (24 hours) since sets don't change often
        if (useCache) {
          await _cacheManager.set(cacheKey, data, Duration(hours: 24));
          LoggingService.debug('Cached set search results for: $setName');
        }
        
        return data;
      } else {
        LoggingService.debug('Set search failed with status: ${response.statusCode}');
        return {'data': [], 'count': 0};
      }
    } catch (e) {
      LoggingService.debug('Error searching sets: $e');
      return {'data': [], 'count': 0};
    }
  }
  
  // Get all sets - primarily for UI display and selection
  Future<List<Map<String, dynamic>>> getAllSets({bool useCache = true}) async {
    try {
      final cacheKey = 'all_sets';
      final cacheEntry = _cache[cacheKey];
      
      // Return from cache if available
      if (useCache && cacheEntry != null && !cacheEntry.isExpired) {
        return (cacheEntry.data as List).cast<Map<String, dynamic>>();
      }
      
      // Try from persistent cache
      if (useCache) {
        final cachedResult = await _cacheManager.get(cacheKey);
        if (cachedResult != null) {
          LoggingService.debug('Retrieved all sets from persistent cache');
          return (cachedResult as List).cast<Map<String, dynamic>>();
        }
      }
      
      final response = await _dio.get('/sets', queryParameters: {
        'orderBy': '-releaseDate', // Newest sets first
        'pageSize': '250'          // Get all sets
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> sets = response.data['data'];
        final formattedSets = sets.map((set) => set as Map<String, dynamic>).toList();
        
        // Cache the response
        _cache[cacheKey] = _CacheEntry(formattedSets);
        
        // Also cache in persistent storage (for 7 days since sets don't change often)
        if (useCache) {
          await _cacheManager.set(cacheKey, formattedSets, Duration(days: 7));
        }
        
        return formattedSets;
      } else {
        return [];
      }
    } catch (e) {
      LoggingService.debug('Error fetching all sets: $e');
      return [];
    }
  }

  // Clear cache for a specific search
  Future<void> clearSearchCache(String query, {
    int page = 1,
    int pageSize = 20,
    String orderBy = 'name',
    bool orderByDesc = false,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'page': '$page',
      'pageSize': '$pageSize',
      'orderBy': orderByDesc ? '-$orderBy' : orderBy,
    };
    
    final cacheKey = _createCacheKey('/cards', queryParams);
    await _cacheManager.clear(cacheKey);
    LoggingService.debug('Cleared cache for search: $query');
  }
  
  // Clear all search caches
  Future<void> clearAllSearchCaches() async {
    // This would require enhancements to CustomCacheManager to clear by prefix
    // For now, we can implement a placeholder
    LoggingService.debug('Attempting to clear all search caches');
    // Implementation would depend on how we want to handle bulk cache clearing
  }

  // Helper method to create cache keys
  String _createCacheKey(String endpoint, Map<String, String> queryParams) {
    final sortedParams = Map.fromEntries(queryParams.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return '$endpoint:${sortedParams.toString()}';
  }
}
