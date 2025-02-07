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
}
