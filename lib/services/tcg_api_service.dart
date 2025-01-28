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
    'Ex Cards': 'supertype:"pokemon ex"',
    'VMAX': 'supertype:"VMAX"',
    'Trainer Gallery': 'set.id:swsh12tg OR set.id:swsh11tg',
  };

  static const Map<String, String> setSearchQueries = {
    'Surging Sparks': 'set.id:sv8',  // Updated correct ID
    'Prismatic Evolution': 'set.id:sv9',  // Updated correct ID
    'Paldea Evolved': 'set.id:sv2',
    'Crown Zenith': 'set.id:swsh12pt5',
    'Silver Tempest': 'set.id:swsh12',
    'Lost Origin': 'set.id:swsh11',
    'Scarlet & Violet': 'set.id:sv1',
    'Paradox Rift': 'set.id:sv4',
  };

  static const Map<String, String> sortOptions = {
    'cardmarket.prices.averageSellPrice': 'Price (High to Low)',
    '-cardmarket.prices.averageSellPrice': 'Price (Low to High)',
    'name': 'Name (A to Z)',
    '-name': 'Name (Z to A)',
    'set.releaseDate': 'Release Date (Newest)',
    '-set.releaseDate': 'Release Date (Oldest)',
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

  // Update the searchCards method to handle different search patterns
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
        // First split by space to separate name from number
        final parts = query.trim().split(RegExp(r'\s+'));
        
        // Check if the last part contains a number
        final lastPart = parts.last;
        final numberMatch = RegExp(r'(\d+)(?:/(\d+))?').firstMatch(lastPart);
        
        if (numberMatch != null) {
          // Extract just the card number (before the slash)
          final cardNumber = numberMatch.group(1)!;
          
          // Get the name part if it exists (everything before the number)
          final name = parts.length > 1 
              ? parts.sublist(0, parts.length - 1).join(' ')
              : '';
              
          // Try all possible number formats (regular, padded)
          final paddedNumber = cardNumber.padLeft(3, '0');
          final unPaddedNumber = cardNumber.replaceFirst(RegExp(r'^0+'), '');
          
          if (name.isNotEmpty) {
            // Search with name and both number formats
            finalQuery = 'name:"$name" (number:"$cardNumber" OR number:"$paddedNumber" OR number:"$unPaddedNumber")';
          } else {
            // Number only search with both formats
            finalQuery = '(number:"$cardNumber" OR number:"$paddedNumber" OR number:"$unPaddedNumber")';
          }
        } else {
          // Regular name search
          finalQuery = 'name:"*${query.trim()}*"';
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
}
