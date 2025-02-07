import 'package:dio/dio.dart';

class TcgApiService {
  static final TcgApiService _instance = TcgApiService._internal();
  final Dio _dio;
  
  factory TcgApiService() => _instance;
  
  TcgApiService._internal() : _dio = Dio(BaseOptions(
    baseUrl: 'https://api.pokemontcg.io/v2',
    headers: {'X-Api-Key': 'eebb53a0-319a-4231-9244-fd7ea48b5d2c'},
  ));

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

  // Core search method
  Future<Map<String, dynamic>> searchCards({
    required String query,
    int page = 1,
    int pageSize = 30,
    String orderBy = 'number',
    bool orderByDesc = false,
  }) async {
    // Initialize with raw query as fallback
    String searchQuery = query;
    
    try {
      // Basic query cleaning
      final cleanQuery = query.trim();
      
      // Determine search type and format query
      if (cleanQuery.startsWith('set.id:')) {
        searchQuery = cleanQuery; // Pass through set searches unchanged
      } else if (RegExp(r'^\d+(?:/\d+)?$').hasMatch(cleanQuery)) {
        searchQuery = 'number:$cleanQuery';
      } else {
        // Handle name search - strip any existing name: prefix first
        final nameQuery = cleanQuery.replaceAll('name:', '').replaceAll('"', '').trim();
        searchQuery = 'name:*$nameQuery*'; // Single wildcard at end
      }

      print('Making API request:');
      print('Query: $searchQuery');
      print('Sort: ${orderByDesc ? '-' : ''}$orderBy');

      final response = await _dio.get('/cards', queryParameters: {
        'q': searchQuery,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        'orderBy': orderByDesc ? '-$orderBy' : orderBy,
      });

      final totalCount = response.data['totalCount'] ?? 0;
      print('Success - Found $totalCount cards');
      return response.data;

    } on DioException catch (e) {
      print('Search error: $e');
      print('Raw query: $query');
      print('Failed query: $searchQuery');
      return {'data': [], 'totalCount': 0, 'page': page};
    } catch (e) {
      print('Unexpected error: $e');
      return {'data': [], 'totalCount': 0, 'page': page};
    }
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

  // Search an entire set
  Future<Map<String, dynamic>> searchSet(String setId) async {
    return searchCards(
      query: 'set.id:$setId',
      orderBy: 'number',
      orderByDesc: false,
      pageSize: 200,
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
    // Scarlet & Violet Era
    'sv8pt5': 'https://images.pokemontcg.io/sv8pt5/logo.png', // Prismatic Evolution
    'sv8': 'https://images.pokemontcg.io/sv8/logo.png',       // Surging Sparks
    'sv3pt5': 'https://images.pokemontcg.io/sv3pt5/logo.png', // 151
    'sv5': 'https://images.pokemontcg.io/sv5/logo.png',       // Temporal Forces
    'sv4': 'https://images.pokemontcg.io/sv4/logo.png',       // Paradox Rift
    'sv3': 'https://images.pokemontcg.io/sv3/logo.png',       // Obsidian Flames
    'sv2': 'https://images.pokemontcg.io/sv2/logo.png',       // Paldea Evolved
    'sv1': 'https://images.pokemontcg.io/sv1/logo.png',       // Scarlet & Violet Base

    // Sword & Shield Era
    'swsh12pt5': 'https://images.pokemontcg.io/swsh12pt5/logo.png', // Crown Zenith
    'swsh12': 'https://images.pokemontcg.io/swsh12/logo.png',       // Silver Tempest
    'swsh11': 'https://images.pokemontcg.io/swsh11/logo.png',       // Lost Origin
    'swsh10': 'https://images.pokemontcg.io/swsh10/logo.png',       // Astral Radiance
    'swsh9': 'https://images.pokemontcg.io/swsh9/logo.png',         // Brilliant Stars

    // Classic Sets
    'base1': 'https://images.pokemontcg.io/base1/logo.png',    // Base Set
    'base2': 'https://images.pokemontcg.io/base2/logo.png',    // Jungle
    'base3': 'https://images.pokemontcg.io/base3/logo.png',    // Fossil
    'base5': 'https://images.pokemontcg.io/base5/logo.png',    // Team Rocket
    'gym1': 'https://images.pokemontcg.io/gym1/logo.png',      // Gym Heroes
    'gym2': 'https://images.pokemontcg.io/gym2/logo.png',      // Gym Challenge
    'neo1': 'https://images.pokemontcg.io/neo1/logo.png',      // Neo Genesis
    'neo2': 'https://images.pokemontcg.io/neo2/logo.png',      // Neo Discovery
    'neo3': 'https://images.pokemontcg.io/neo3/logo.png',      // Neo Revelation
    'neo4': 'https://images.pokemontcg.io/neo4/logo.png',      // Neo Destiny
  };
}
