import '../services/logging_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class MtgApiService {
  final String _baseUrl = 'https://api.scryfall.com';

  Future<Map<String, dynamic>> searchCards({
    required String query,
    int page = 1,
    int pageSize = 20,
    String orderBy = 'usd', // Default to USD price
    bool orderByDesc = true, // Default to descending (high to low)
  }) async {
    try {
      // Skip empty queries
      if (query.trim().isEmpty) {
        return {'data': [], 'totalCount': 0, 'hasMore': false};
      }

      // Format the query correctly for Scryfall
      String scryfallQuery;
      if (query.startsWith('set.id:')) {
        final setCode = query.substring(7).trim();
        scryfallQuery = 'e:$setCode';
      } else {
        scryfallQuery = query;
      }
      
      // Always use price sorting for MTG
      String sortParam = 'usd';  // Always sort by price
      String sortDir = 'desc';   // Always high to low
      
      // Create direct URL
      final directUrl = '$_baseUrl/cards/search?q=${Uri.encodeComponent(scryfallQuery)}&order=$sortParam&dir=$sortDir&page=$page';
      
      // Make direct API call with timeout
      final response = await http.get(Uri.parse(directUrl))
        .timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        // Try alternate search format if the first one fails
        if (query.startsWith('set.id:') && scryfallQuery.startsWith('e:')) {
          final setCode = query.substring(7).trim();
          scryfallQuery = 'set:$setCode';
          
          final alternateUrl = '$_baseUrl/cards/search?q=${Uri.encodeComponent(scryfallQuery)}';
          
          final alternateResponse = await http.get(Uri.parse(alternateUrl))
            .timeout(const Duration(seconds: 15));
          
          if (alternateResponse.statusCode == 200) {
            final data = json.decode(alternateResponse.body);
            return _processResponse(data, query);
          }
        }
        
        return {'data': [], 'totalCount': 0, 'hasMore': false};
      }
      
      // Parse successful response
      final data = json.decode(response.body);
      return _processResponse(data, query);
      
    } catch (e, stack) {
      LoggingService.debug('MTG search exception: $e');
      return {'data': [], 'totalCount': 0, 'hasMore': false};
    }
  }
  
  Map<String, dynamic> _processResponse(Map<String, dynamic> data, String originalQuery) {
    final List<dynamic> cards = data['data'] ?? [];
    final int totalCards = data['total_cards'] ?? 0;
    final bool hasMore = data['has_more'] ?? false;
    
    final List<Map<String, dynamic>> processedCards = [];
    
    for (final card in cards) {
      try {
        String imageUrl = '';
        String largeImageUrl = '';
        
        if (card['image_uris'] != null) {
          imageUrl = card['image_uris']['normal'] ?? '';
          largeImageUrl = card['image_uris']['large'] ?? '';
        } else if (card['card_faces'] != null && 
                  (card['card_faces'] as List).isNotEmpty &&
                  card['card_faces'][0]['image_uris'] != null) {
          imageUrl = card['card_faces'][0]['image_uris']['normal'] ?? '';
          largeImageUrl = card['card_faces'][0]['image_uris']['large'] ?? '';
        }
        
        if (imageUrl.isEmpty) {
          continue;
        }
        
        double price = 0.0;
        if (card['prices'] != null) {
          if (card['prices']['usd'] != null && card['prices']['usd'] != "null") {
            price = double.tryParse(card['prices']['usd'].toString()) ?? 0.0;
          } else if (card['prices']['usd_foil'] != null && card['prices']['usd_foil'] != "null") {
            price = double.tryParse(card['prices']['usd_foil'].toString()) ?? 0.0;
          } else if (card['prices']['eur'] != null && card['prices']['eur'] != "null") {
            price = double.tryParse(card['prices']['eur'].toString()) ?? 0.0;
          }
        }
        
        processedCards.add({
          'id': card['id'] ?? '',
          'name': card['name'] ?? 'Unknown Card',
          'set': {
            'id': card['set'] ?? '',
            'name': card['set_name'] ?? 'Unknown Set',
          },
          'number': card['collector_number'] ?? '',
          'rarity': card['rarity'] ?? 'common',
          'imageUrl': imageUrl,
          'largeImageUrl': largeImageUrl,
          'price': price,
          'types': card['type_line'] ?? '',
          'artist': card['artist'] ?? 'Unknown',
          'isMtg': true,  // Flag this as an MTG card
        });
      } catch (e) {
        // Silent catch to continue processing other cards
      }
    }
    
    // Sort by price high to low as default
    processedCards.sort((a, b) => 
      (b['price'] as double).compareTo(a['price'] as double)
    );
    
    return {
      'data': processedCards,
      'totalCount': totalCards,
      'hasMore': hasMore,
      'query': originalQuery,
    };
  }

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
      return null;
    }
  }
}
