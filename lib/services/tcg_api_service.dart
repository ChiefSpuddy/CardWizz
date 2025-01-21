import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tcg_card.dart';

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
    'Paldea Evolved': 'set.id:sv2',
    'Crown Zenith': 'set.id:swsh12pt5',
    'Silver Tempest': 'set.id:swsh12',
    'Lost Origin': 'set.id:swsh11',
    'Scarlet & Violet': 'set.id:sv1',
    'Paradox Rift': 'set.id:sv4',
    'Surging Sparks': 'set.id:sv5pt5', // Added new set
    'Prismatic Evolution': 'set.id:sv5', // Added new set
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

  Future<Map<String, dynamic>> searchCards(String query, {
    String? customQuery,
    String sortBy = 'cardmarket.prices.averageSellPrice',  // Default to price high to low
    bool ascending = false,
  }) async {
    try {
      final searchQuery = customQuery ?? 
          popularSearchQueries[query] ?? 
          setSearchQueries[query] ??
          'name:"*$query*"';

      final response = await http.get(
        Uri.parse('$_baseUrl/cards').replace(
          queryParameters: {
            'q': searchQuery,
            'select': 'id,name,images,cardmarket,number,set,rarity', // Added rarity
            'orderBy': ascending ? sortBy : '-$sortBy',
            'page': '1',
            'pageSize': '30',
          },
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      throw Exception('Failed to search cards');
    } catch (e) {
      print('Search error: $e');
      throw Exception('Error searching cards');
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
}
