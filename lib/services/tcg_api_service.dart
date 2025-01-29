import 'dart:convert';
import 'package:http/http.dart' as http;

class TcgApiService {
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

  static const Map<String, String> setSearchQueries = {
    'Prismatic Evolution': 'set.id:sv10',
    'Surging Sparks': 'set.id:sv8',
    'Stellar Crown': 'set.id:sv7',
    'Twilight Masquerade': 'set.id:sv6',
    'Paldean Fates': 'set.id:sv5',      // Corrected ID
    'Paradox Rift': 'set.id:sv4',       // Corrected ID
    'Obsidian Flames': 'set.id:sv3',    // Verified ID
    'Temporal Forces': 'set.id:sv3p5',   // Corrected ID
    'Paldea Evolved': 'set.id:sv2',     // Corrected ID
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
    'sv10': ['Prismatic Evolution', 'Prismatic', 'Evolution'],
    'sv8': ['Surging Sparks', 'Surging', 'Sparks'],
    'sv7': ['Stellar Crown', 'Stellar', 'Crown'],
    'sv6': ['Twilight Masquerade', 'Twilight', 'Masquerade'],
    'sv5': ['Paldean Fates', 'Paldean', 'Fates'],
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

  Future<Map<String, dynamic>> searchCards(
    String query, {
    String? sortBy,
    bool ascending = true,
    int page = 1,
    int pageSize = 60,
    String? customQuery,
  }) async {
    try {
      String finalQuery;
      
      if (customQuery != null) {
        finalQuery = customQuery;
      } else {
        // Check if query matches a set name or alias
        final setId = _getSetIdFromName(query);
        if (setId != null) {
          finalQuery = 'set.id:$setId';
          print('Matched set ID: $setId for query: $query'); // Add debug print
        } else {
          // Use existing name/number search logic
          final parts = query.trim().split(RegExp(r'\s+'));
          final lastPart = parts.last;
          final numberMatch = RegExp(r'(\d+)(?:/(\d+))?').firstMatch(lastPart);
          
          if (numberMatch != null) {
            final cardNumber = numberMatch.group(1)!;
            final name = parts.length > 1 
                ? parts.sublist(0, parts.length - 1).join(' ')
                : '';
                
            final paddedNumber = cardNumber.padLeft(3, '0');
            final unPaddedNumber = cardNumber.replaceFirst(RegExp(r'^0+'), '');
            
            if (name.isNotEmpty) {
              finalQuery = 'name:"$name" (number:"$cardNumber" OR number:"$paddedNumber" OR number:"$unPaddedNumber")';
            } else {
              finalQuery = '(number:"$cardNumber" OR number:"$paddedNumber" OR number:"$unPaddedNumber")';
            }
          } else {
            finalQuery = 'name:"*${query.trim()}*"';
          }
        }
      }

      final queryParams = {
        'q': finalQuery,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (sortBy != null) {
        queryParams['orderBy'] = ascending ? sortBy : '-$sortBy';
      }

      print('API Query: $queryParams');
      return await _get('cards', queryParams);
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCardDetails(String cardId) async {
    final url = Uri.parse('$_baseUrl/cards/$cardId');
    final response = await http.get(url, headers: _headers);
    
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
    final response = await http.get(uri, headers: _headers);
    
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
