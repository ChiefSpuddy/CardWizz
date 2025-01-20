import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tcg_card.dart';

class TcgApiService {
  static const _baseUrl = 'https://api.pokemontcg.io/v2';
  static const _apiKey = 'eebb53a0-319a-4231-9244-fd7ea48b5d2c';
  
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'X-Api-Key': _apiKey,
  };

  Future<List<TcgCard>> searchCards(String query) async {
    try {
      final url = Uri.parse('$_baseUrl/cards').replace(
        queryParameters: {
          'q': 'name:"*$query*"',
          'orderBy': 'name',
          'pageSize': '20',
        },
      );

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((card) => TcgCard(
                  id: card['id'],
                  name: card['name'],
                  imageUrl: card['images']['small'],
                  setName: card['set']['name'],
                  rarity: card['rarity'],
                  price: card['cardmarket']?['prices']?['averageSellPrice']?.toDouble(),
                ))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching cards: $e');
      return [];
    }
  }
}
