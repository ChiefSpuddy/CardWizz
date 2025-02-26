import 'dart:convert';
import 'package:http/http.dart' as http;

class MtgApiService {
  final String _scryfallApiUrl = 'https://api.scryfall.com';
  
  /// Search for Magic: The Gathering cards
  Future<Map<String, dynamic>> searchCards({
    required String query,
    int page = 1,
    int pageSize = 20,
    String orderBy = 'name',
    bool orderByDesc = false,
  }) async {
    try {
      // Convert page to Scryfall's format (1-indexed)
      final scryfallPage = page;
      
      // Convert our sort parameter to Scryfall's format
      String sort = 'name';
      String dir = 'auto';
      
      // Convert our sort params to Scryfall format
      switch (orderBy) {
        case 'name':
          sort = 'name';
          dir = orderByDesc ? 'desc' : 'asc';
          break;
        case 'cardmarket.prices.averageSellPrice':
          sort = 'usd';
          dir = orderByDesc ? 'desc' : 'asc';
          break;
        case 'number':
          sort = 'collector_number';
          dir = orderByDesc ? 'desc' : 'asc';
          break;
      }
      
      // Handle set.id: prefix
      if (query.startsWith('set.id:')) {
        query = 'e:${query.substring(7)}';
      }
      
      // Prepare query params
      final queryParams = {
        'q': query,
        'page': scryfallPage.toString(),
        'order': sort,
        'dir': dir,
      };
      
      print('MTG API query: ${_scryfallApiUrl}/cards/search?${Uri(queryParameters: queryParams).query}');
      
      // Make API call
      final response = await http.get(
        Uri.parse('${_scryfallApiUrl}/cards/search?${Uri(queryParameters: queryParams).query}'),
      );
      
      if (response.statusCode != 200) {
        print('MTG API error: ${response.statusCode} - ${response.body}');
        return {
          'data': [],
          'totalCount': 0,
          'hasMore': false,
        };
      }
      
      // Parse response
      final data = json.decode(response.body);
      final List<dynamic> cards = data['data'] ?? [];
      final hasMore = data['has_more'] ?? false;
      final totalCount = data['total_cards'] ?? cards.length;
      
      // Convert Scryfall card format to our app's format
      final transformedCards = cards.map((card) {
        return {
          'id': card['id'],
          'name': card['name'],
          'set': {
            'id': card['set'],
            'name': card['set_name'],
          },
          'number': card['collector_number'],
          'rarity': card['rarity'],
          'imageUrl': card['image_uris']?['normal'] ?? card['card_faces']?[0]?['image_uris']?['normal'],
          'largeImageUrl': card['image_uris']?['large'] ?? card['card_faces']?[0]?['image_uris']?['large'],
          'price': double.tryParse(card['prices']?['usd'] ?? '0') ?? 0.0,
          'types': card['type_line'],
          'artist': card['artist'],
        };
      }).toList();
      
      return {
        'data': transformedCards,
        'totalCount': totalCount,
        'hasMore': hasMore,
      };
    } catch (e) {
      print('Error in MTG search: $e');
      return {
        'data': [],
        'totalCount': 0,
        'hasMore': false,
      };
    }
  }
  
  /// Get details for a specific set
  Future<Map<String, dynamic>?> getSetDetails(String setCode) async {
    try {
      final response = await http.get(Uri.parse('${_scryfallApiUrl}/sets/$setCode'));
      
      if (response.statusCode != 200) {
        return null;
      }
      
      final data = json.decode(response.body);
      
      return {
        'id': data['code'],
        'name': data['name'],
        'releaseDate': data['released_at'],
        'total': data['card_count'],
        'logo': 'https://c2.scryfall.com/file/scryfall-symbols/sets/${data['code']}.svg',
      };
    } catch (e) {
      print('Error getting set details: $e');
      return null;
    }
  }
}
