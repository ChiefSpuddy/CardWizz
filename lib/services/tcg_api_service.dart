import 'dart:convert';
import 'dart:math' show min;  // Add this import
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';  // Add this import
import '../models/tcg_card.dart';  // Add this import

class TcgApiService {
  static final TcgApiService _instance = TcgApiService._internal();
  final http.Client _client = http.Client();
  final Dio _dio;  // Add this field

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

  // Add these new maps for better set matching
  static const Map<String, List<String>> setAliases = {
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
    
    // First try exact match from setSearchQueries
    for (final entry in setSearchQueries.entries) {
      if (entry.key.toLowerCase() == query) {
        return entry.value.replaceAll('set.id:', '');
      }
    }

    // Then try aliases and partial matches
    for (final entry in setAliases.entries) {
      final aliases = entry.value.map((e) => e.toLowerCase()).toList();
      // Check if query matches any alias completely
      if (aliases.contains(query)) {
        return entry.key;
      }
      // Check if query is part of any alias
      for (final alias in aliases) {
        if (alias.contains(query) || query.contains(alias)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  // Update searchCards to handle all sorting cases consistently
  Future<Map<String, dynamic>> searchCards({
    required String query,
    int page = 1,
    int pageSize = 30,
    String orderBy = 'cardmarket.prices.averageSellPrice',
    bool orderByDesc = true,
  }) async {
    try {
      // Always get all pages for consistent sorting
      final firstPageResponse = await _dio.get('/cards', queryParameters: {
        'q': query,
        'page': '1',
        'pageSize': pageSize.toString(),
        'select': 'id,name,number,images,set,rarity,cardmarket',
      });
      
      final totalCount = firstPageResponse.data['totalCount'] as int;
      final totalPages = (totalCount / pageSize).ceil();
      
      // Collect all cards
      List<dynamic> allCards = [...(firstPageResponse.data['data'] as List)];
      
      // Fetch remaining pages in parallel
      if (totalPages > 1) {
        final futures = <Future>[];
        for (var p = 2; p <= totalPages; p++) {
          futures.add(_dio.get('/cards', queryParameters: {
            'q': query,
            'page': p.toString(),
            'pageSize': pageSize.toString(),
            'select': 'id,name,number,images,set,rarity,cardmarket',
          }));
        }
        
        final responses = await Future.wait(futures);
        for (final response in responses) {
          allCards.addAll(response.data['data'] as List);
        }
      }

      // Sort all cards based on criteria
      allCards.sort((a, b) {
        switch (orderBy) {
          case 'cardmarket.prices.averageSellPrice':
            final priceA = _extractPrice(a);
            final priceB = _extractPrice(b);
            
            if (priceA == 0 && priceB > 0) return 1;
            if (priceB == 0 && priceA > 0) return -1;
            if (priceA == 0 && priceB == 0) return 0;
            
            return orderByDesc ? priceB.compareTo(priceA) : priceA.compareTo(priceB);
          
          case 'name':
            final nameA = a['name'] as String;
            final nameB = b['name'] as String;
            return orderByDesc ? nameB.compareTo(nameA) : nameA.compareTo(nameB);
          
          case 'number':
            // Convert numbers to integers for proper numeric sorting
            final numA = int.tryParse(a['number'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final numB = int.tryParse(b['number'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return orderByDesc ? numB.compareTo(numA) : numA.compareTo(numB);
          
          default:
            return 0;
        }
      });

      // Return paginated result from sorted cards
      final startIndex = (page - 1) * pageSize;
      final endIndex = min(startIndex + pageSize, allCards.length);
      final paginatedCards = allCards.sublist(startIndex, endIndex);

      // Debug logging
      print('\nSorted by: $orderBy (${orderByDesc ? 'DESC' : 'ASC'})');
      print('First 5 results:');
      for (var i = 0; i < min(5, paginatedCards.length); i++) {
        final card = paginatedCards[i];
        switch (orderBy) {
          case 'cardmarket.prices.averageSellPrice':
            print('[$i]: \$${_extractPrice(card).toStringAsFixed(2)}');
            break;
          case 'name':
            print('[$i]: ${card['name']}');
            break;
          case 'number':
            print('[$i]: ${card['number']}');
            break;
        }
      }

      return {
        'data': paginatedCards,
        'page': page,
        'count': paginatedCards.length,
        'totalCount': totalCount,
      };
    } catch (e) {
      print('Error searching cards: $e');
      return {'data': [], 'count': 0, 'totalCount': 0};
    }
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
