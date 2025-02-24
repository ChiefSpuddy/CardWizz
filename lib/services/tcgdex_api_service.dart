import 'package:http/http.dart' as http;
import 'dart:convert';

class TcgdexApiService {
  static const String _baseUrl = 'https://play.limitlesstcg.com/api';
  static const String _apiKey = 'YOUR_API_KEY_HERE'; // You'll need to get this from Limitless TCG
  
  Future<List<Map<String, dynamic>>> getJapaneseSets() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/decks/sets/jp'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode != 200) {
        print('❌ Failed to fetch Japanese sets: ${response.statusCode}');
        return _getFallbackSets();
      }

      final List<dynamic> sets = jsonDecode(response.body);
      final japaneseSets = <Map<String, dynamic>>[];

      for (final set in sets) {
        japaneseSets.add({
          'id': set['setId'],
          'name': set['name']?['en'] ?? set['name']?['jp'] ?? set['setId'],
          'releaseDate': set['releaseDate'],
          'logo': 'https://limitlesstcg.nyc3.cdn.digitaloceanspaces.com/jp/${set['setId']}/${set['setId']}_Logo_EN.png',
          'symbol': 'https://limitlesstcg.nyc3.cdn.digitaloceanspaces.com/jp/${set['setId']}/${set['setId']}_Symbol.png',
          'total': set['totalCards'] ?? 0,
          'series': 'Japanese',
        });
      }

      print('📦 Found ${japaneseSets.length} Japanese sets');
      return japaneseSets;
    } catch (e) {
      print('❌ Limitless API error: $e');
      return _getFallbackSets();
    }
  }

  List<Map<String, dynamic>> _getFallbackSets() {
    // Fallback data if API fails
    return [
      {
        'id': 'wild-force',
        'name': 'Wild Force (Japan)',
        'releaseDate': '2024/02/23',
        'logo': 'https://limitlesstcg.nyc3.cdn.digitaloceanspaces.com/jp/SV5B/SV5B_Logo_EN.png',
        'symbol': 'https://limitlesstcg.nyc3.cdn.digitaloceanspaces.com/jp/SV5B/SV5B_Symbol.png',
        'total': 67,
        'series': 'Scarlet & Violet'
      },
      {
        'id': 'raging-surf',
        'name': 'Raging Surf (Japan)', 
        'releaseDate': '2024/03/22',
        'total': 63,
        'series': 'Scarlet & Violet'
      },
      // Add more fallback sets here
    ];
  }

  Future<Map<String, dynamic>> searchJapaneseSet(String setId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cards?setId=$setId&language=jp'),
      );

      if (response.statusCode != 200) {
        return {'data': [], 'totalCount': 0};
      }

      final List<dynamic> cards = jsonDecode(response.body);
      final formattedCards = cards.map((card) => {
        'id': card['id'],
        'number': card['number'],
        'name': card['name']?['en'] ?? card['name']?['jp'] ?? 'Unknown',
        'images': {
          'small': 'https://limitlesstcg.nyc3.cdn.digitaloceanspaces.com/jp/$setId/cards/${card['number']}.jpg',
          'large': 'https://limitlesstcg.nyc3.cdn.digitaloceanspaces.com/jp/$setId/cards/${card['number']}_hires.jpg',
        },
        'set': {
          'id': setId,
          'name': card['setName']?['en'] ?? 'Japanese Set',
          'series': 'Japanese',
          'total': cards.length,
        }
      }).toList();

      return {
        'data': formattedCards,
        'totalCount': formattedCards.length,
        'setInfo': {
          'id': setId,
          'name': formattedCards.first['set']['name'],
          'total': formattedCards.length,
        }
      };

    } catch (e) {
      print('❌ Limitless API error: $e');
      return {'data': [], 'totalCount': 0};
    }
  }
}
