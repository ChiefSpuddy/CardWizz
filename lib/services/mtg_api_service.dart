import 'dart:convert';
import 'package:http/http.dart' as http;

class MtgApiService {
  final String _baseUrl = 'https://api.scryfall.com';

  Future<Map<String, dynamic>> searchCards({
    required String query,
    int page = 1,
    int pageSize = 20,
    String orderBy = 'name',
    bool orderByDesc = false,
  }) async {
    try {
      // Clean up query
      final String cleanQuery = query.startsWith('set.id:') 
          ? 'set:${query.substring(7)}' // Convert our set.id: format to Scryfall's set: format
          : query;
      
      final queryParams = {
        'q': cleanQuery,
        'page': page.toString(),
        'order': orderBy,
        'dir': orderByDesc ? 'desc' : 'asc',
      };

      print('MTG API Request: $_baseUrl/cards/search?${Uri(queryParameters: queryParams).query}');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/cards/search?${Uri(queryParameters: queryParams).query}'),
      );

      if (response.statusCode != 200) {
        print('MTG API error: ${response.statusCode}');
        return {
          'data': [],
          'totalCount': 0,
          'hasMore': false,
        };
      }

      // Parse the JSON response
      final data = json.decode(response.body);
      final List<Map<String, dynamic>> transformedCards = [];
      
      // Process each card
      for (final card in data['data'] as List) {
        // Extract image URL based on card layout
        String imageUrl;
        String largeImageUrl;
        
        if (card['card_faces'] != null && card['card_faces'].length > 0) {
          // Double-faced card - use front face
          final frontFace = card['card_faces'][0];
          imageUrl = frontFace['image_uris']?['normal'] ?? '';
          largeImageUrl = frontFace['image_uris']?['large'] ?? '';
        } else {
          // Regular card
          imageUrl = card['image_uris']?['normal'] ?? '';
          largeImageUrl = card['image_uris']?['large'] ?? '';
        }

        // Skip cards without images
        if (imageUrl.isEmpty) continue;
        
        // Process price
        double price = 0.0;
        if (card['prices'] != null && card['prices']['usd'] != null) {
          price = double.tryParse(card['prices']['usd']) ?? 0.0;
        }
        
        // Create transformed card object in our app's format
        transformedCards.add({
          'id': card['id'],
          'name': card['name'],
          'set': {
            'id': card['set'],
            'name': card['set_name'],
          },
          'number': card['collector_number'],
          'rarity': card['rarity'],
          'imageUrl': imageUrl,
          'largeImageUrl': largeImageUrl,
          'price': price,
          'types': card['type_line'] ?? '',
          'artist': card['artist'] ?? '',
        });
      }

      return {
        'data': transformedCards,
        'totalCount': data['total_cards'] ?? transformedCards.length,
        'hasMore': data['has_more'] ?? false,
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
      final response = await http.get(Uri.parse('$_baseUrl/sets/$setCode'));
      
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
