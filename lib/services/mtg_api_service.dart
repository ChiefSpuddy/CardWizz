import 'package:http/http.dart' as http;
import 'dart:convert';

class MtgApiService {
  static const String _baseUrl = 'https://api.scryfall.com';

  Future<Map<String, dynamic>> searchCards({
    required String query,
    String orderBy = 'name',
    bool orderByDesc = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cards/search').replace(
          queryParameters: {
            'q': query,
            'order': orderBy,
            'dir': orderByDesc ? 'desc' : 'asc',
            'page': page.toString(),
            'unique': 'prints',
          },
        ),
      );

      if (response.statusCode != 200) {
        print('MTG search error: ${response.statusCode}');
        return {'data': [], 'totalCount': 0};
      }

      final data = jsonDecode(response.body);
      
      // Convert Scryfall format to match our app's format
      final cards = (data['data'] as List).map((card) => {
        'id': card['id'],
        'name': card['name'],
        'number': card['collector_number'],
        'rarity': card['rarity'],
        'imageUrl': card['image_uris']?['small'] ?? card['card_faces']?[0]?['image_uris']?['small'],
        'largeImageUrl': card['image_uris']?['large'] ?? card['card_faces']?[0]?['image_uris']?['large'],
        'price': card['prices']?['usd']?.toString(),
        'set': {
          'id': card['set'],
          'name': card['set_name'],
          'series': card['set_type'],
          'total': data['total_cards'],
        }
      }).toList();

      return {
        'data': cards,
        'totalCount': data['total_cards'] as int,
      };
    } catch (e) {
      print('MTG API error: $e');
      return {'data': [], 'totalCount': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getSets() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/sets'));
      
      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      return (data['data'] as List)
        .where((set) => set['set_type'] != 'token' && set['card_count'] > 0)
        .map((set) => {
          'id': set['code'],
          'name': set['name'],
          'releaseDate': set['released_at'],
          'logo': set['icon_svg_uri'],
          'symbol': set['icon_svg_uri'],
          'total': set['card_count'],
          'series': set['set_type'],
        }).toList();
    } catch (e) {
      print('MTG sets error: $e');
      return [];
    }
  }
}
