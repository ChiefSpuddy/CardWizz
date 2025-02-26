import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tcg_card.dart';

class ScryfallApiService {
  static const String _baseUrl = 'https://api.scryfall.com';

  /// Convert application query to Scryfall format
  String _convertQuery(String query) {
    print('Converting MTG query: $query');
    
    // Handle set queries correctly
    if (query.startsWith('set.id:')) {
      final setId = query.substring(7);
      return 'set:$setId';
    }
    
    return query;
  }

  /// Search for MTG cards with the given query
  Future<List<TcgCard>> searchCards(String query, {int page = 1}) async {
    final convertedQuery = _convertQuery(query);
    print('MTG API request: /cards/search?q=${Uri.encodeComponent(convertedQuery)}&page=$page');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/cards/search?q=${Uri.encodeComponent(convertedQuery)}&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final totalCards = data['total_cards'];
      print('MTG search successful, found $totalCards cards');
      
      final cards = (data['data'] as List).map((card) => _convertToTcgCard(card)).toList();
      
      // Log a sample of the results for debugging
      for (var card in cards.take(20)) {
        print('MTG card: ${card.name}, Set: ${card.setName}, ImageURL: ${card.imageUrl}');
      }
      
      return cards;
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Failed to search MTG cards: ${error['details']}');
    }
  }

  /// Convert a Scryfall card to a TcgCard
  TcgCard _convertToTcgCard(Map<String, dynamic> card) {
    // Handle double-faced cards
    String imageUrl = '';
    String largeImageUrl = '';
    
    if (card['card_faces'] != null && (card['card_faces'] as List).isNotEmpty) {
      // For double-faced cards, use the front face
      final frontFace = card['card_faces'][0];
      imageUrl = frontFace['image_uris']?['small'] ?? '';
      largeImageUrl = frontFace['image_uris']?['normal'] ?? '';
    } else {
      // For regular cards
      imageUrl = card['image_uris']?['small'] ?? '';
      largeImageUrl = card['image_uris']?['normal'] ?? '';
    }

    // Create a TcgSet object from the Scryfall set data
    final tcgSet = TcgSet(
      id: card['set'] ?? '',
      name: card['set_name'] ?? 'Unknown Set',
      series: card['set_type'] ?? '',
      printedTotal: card['set_size'] ?? 0,
      total: card['set_size'] ?? 0, 
      releaseDate: card['released_at'] ?? '',
      images: {
        'logo': 'https://c2.scryfall.com/file/scryfall-symbols/sets/${card['set']}.svg',
        'symbol': 'https://c2.scryfall.com/file/scryfall-symbols/sets/${card['set']}.svg',
      },
    );

    // Create a TcgCard from the Scryfall card data
    return TcgCard(
      id: card['id'] ?? '',
      name: card['name'] ?? 'Unknown Card',
      imageUrl: imageUrl,
      largeImageUrl: largeImageUrl,
      number: card['collector_number']?.toString() ?? '',
      rarity: card['rarity'] ?? '',
      set: tcgSet,
      price: _extractPrice(card),
      types: _extractTypes(card),
      subtypes: card['type_line'] ?? '',
      artist: card['artist'] ?? '',
      rawData: card,
      // Flag this as an MTG card for proper handling in the UI
      // This will be accessed via extension getter in TcgCard
    );
  }

  /// Extract the price from a Scryfall card
  double? _extractPrice(Map<String, dynamic> card) {
    final prices = card['prices'];
    if (prices == null) return null;
    
    // Try USD price first, then EUR if available
    return (prices['usd'] != null) 
        ? double.tryParse(prices['usd']) 
        : (prices['eur'] != null)
            ? double.tryParse(prices['eur'])
            : null;
  }

  /// Extract the types from a Scryfall card
  String _extractTypes(Map<String, dynamic> card) {
    if (card['type_line'] == null) return '';
    
    // Split by "—" to get the main type
    final typeLine = card['type_line'] as String;
    final parts = typeLine.split('—');
    
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    
    return typeLine;
  }
}
