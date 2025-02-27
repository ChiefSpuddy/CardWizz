import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

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
      print('🃏 MTG SEARCH START: "$query"');
      
      // Skip empty queries
      if (query.trim().isEmpty) {
        print('🃏 Empty MTG search query');
        return {'data': [], 'totalCount': 0, 'hasMore': false};
      }

      // Format the query correctly for Scryfall
      String scryfallQuery;
      if (query.startsWith('set.id:')) {
        // Extract set code and format for Scryfall
        final setCode = query.substring(7).trim();
        // Try e: first as it's the more modern syntax
        scryfallQuery = 'e:$setCode';
        print('🃏 MTG set search converted: "$scryfallQuery"');
      } else {
        scryfallQuery = query;
        print('🃏 MTG general search: "$scryfallQuery"');
      }
      
      // Add sorting parameters to the query
      String sortParam = _getScryfallSortField(orderBy);
      String sortDir = orderByDesc ? 'desc' : 'asc';
      
      // Create direct URL for debugging
      final directUrl = '$_baseUrl/cards/search?q=${Uri.encodeComponent(scryfallQuery)}&order=$sortParam&dir=$sortDir&page=$page';
      print('🃏 MTG API URL: $directUrl');
      
      // Make direct API call with timeout
      print('🃏 Making HTTP request...');
      final response = await http.get(Uri.parse(directUrl))
        .timeout(const Duration(seconds: 15));
      
      print('🃏 Response status code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('🃏 MTG search FAILED with status ${response.statusCode}');
        print('🃏 Response body: ${response.body}');
        
        // Try alternate search format if the first one fails
        if (query.startsWith('set.id:') && scryfallQuery.startsWith('e:')) {
          final setCode = query.substring(7).trim();
          scryfallQuery = 'set:$setCode';
          print('🃏 Retrying with alternate syntax: "$scryfallQuery"');
          
          final alternateUrl = '$_baseUrl/cards/search?q=${Uri.encodeComponent(scryfallQuery)}';
          print('🃏 Alternate URL: $alternateUrl');
          
          final alternateResponse = await http.get(Uri.parse(alternateUrl))
            .timeout(const Duration(seconds: 15));
          
          print('🃏 Alternate response status: ${alternateResponse.statusCode}');
          
          if (alternateResponse.statusCode == 200) {
            final data = json.decode(alternateResponse.body);
            return _processResponse(data, query);
          }
        }
        
        return {'data': [], 'totalCount': 0, 'hasMore': false};
      }
      
      // Parse successful response
      print('🃏 MTG search successful, parsing response...');
      final data = json.decode(response.body);
      return _processResponse(data, query);
      
    } catch (e, stack) {
      print('🃏 MTG search exception: $e');
      print('🃏 Stack trace: $stack');
      return {'data': [], 'totalCount': 0, 'hasMore': false};
    }
  }
  
  Map<String, dynamic> _processResponse(Map<String, dynamic> data, String originalQuery) {
    final List<dynamic> cards = data['data'] ?? [];
    final int totalCards = data['total_cards'] ?? 0;
    final bool hasMore = data['has_more'] ?? false;
    
    print('🃏 Found $totalCards total MTG cards');
    print('🃏 Received ${cards.length} cards in this batch');
    
    if (cards.isNotEmpty) {
      final firstCard = cards.first;
      print('🃏 Example card: ${firstCard['name']} (${firstCard['set']})');
      if (firstCard['image_uris'] != null) {
        print('🃏 Has image: YES - ${firstCard['image_uris']['small']}');
      } else if (firstCard['card_faces'] != null) {
        print('🃏 Has card_faces with images: ${firstCard['card_faces'][0]['image_uris'] != null}');
      } else {
        print('🃏 No images found on card');
      }
    }
    
    // Process cards into app format
    final List<Map<String, dynamic>> processedCards = [];
    
    for (final card in cards) {
      try {
        String imageUrl = '';
        String largeImageUrl = '';
        
        // Handle images based on card layout
        if (card['image_uris'] != null) {
          imageUrl = card['image_uris']['normal'] ?? '';
          largeImageUrl = card['image_uris']['large'] ?? '';
        } else if (card['card_faces'] != null && 
                  (card['card_faces'] as List).isNotEmpty &&
                  card['card_faces'][0]['image_uris'] != null) {
          imageUrl = card['card_faces'][0]['image_uris']['normal'] ?? '';
          largeImageUrl = card['card_faces'][0]['image_uris']['large'] ?? '';
        }
        
        // Skip cards without images
        if (imageUrl.isEmpty) {
          print('🃏 Skipping card ${card['name']} - no image');
          continue;
        }
        
        // Process price
        double price = 0.0;
        if (card['prices'] != null) {
          // Try USD price first, then EUR, then TIX
          if (card['prices']['usd'] != null) {
            price = double.tryParse(card['prices']['usd'].toString()) ?? 0.0;
          } else if (card['prices']['eur'] != null) {
            price = double.tryParse(card['prices']['eur'].toString()) ?? 0.0;
          } else if (card['prices']['tix'] != null) {
            price = double.tryParse(card['prices']['tix'].toString()) ?? 0.0;
          }
        }
        
        // Add processed card
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
          'hasPrice': price > 0, // Add flag for cards with price
        });
      } catch (e) {
        print('🃏 Error processing card: $e');
      }
    }
    
    print('🃏 Successfully processed ${processedCards.length} cards');
    if (processedCards.isNotEmpty) {
      print('🃏 First processed card: ${processedCards[0]['name']}');
      print('🃏 With image URL: ${processedCards[0]['imageUrl']}');
    }
    
    return {
      'data': processedCards,
      'totalCount': totalCards,
      'hasMore': hasMore,
      'query': originalQuery,
    };
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

  // Helper method to convert our fields to Scryfall's fields
  String _getScryfallSortField(String orderBy) {
    switch (orderBy) {
      case 'cardmarket.prices.averageSellPrice':
        return 'usd'; // Sort by USD price
      case 'number':
        return 'collector';
      case 'name':
        return 'name';
      case 'releaseDate':
        return 'released';
      default:
        return 'name';
    }
  }
}
