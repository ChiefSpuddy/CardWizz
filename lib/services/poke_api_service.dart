import 'package:http/http.dart' as http;
import 'dart:convert';

class PokeApiService {
  static const int _maxConcurrentRequests = 10;  // Increase for faster loading
  final Map<String, String> _spriteCache = {};
  final Map<String, Map<String, dynamic>> _pokemonCache = {};

  // Optimize sprite URL generation
  String getSpriteUrl(int dexNum) {
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$dexNum.png';
  }

  // Batch fetch Pokemon data with concurrency limit
  Future<List<Map<String, dynamic>>> fetchPokemonBatch(List<int> dexNumbers) async {
    final results = <Map<String, dynamic>>[];
    
    // Process in smaller batches
    for (var i = 0; i < dexNumbers.length; i += _maxConcurrentRequests) {
      final batch = dexNumbers.skip(i).take(_maxConcurrentRequests);
      final futures = batch.map((dexNum) => fetchBasicData(dexNum.toString()));
      final responses = await Future.wait(futures);
      results.addAll(responses.whereType<Map<String, dynamic>>());
    }
    
    return results;
  }

  Future<Map<String, dynamic>?> fetchBasicData(String identifier) async {
    if (_pokemonCache.containsKey(identifier)) {
      return _pokemonCache[identifier];
    }

    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$identifier'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = {
          'name': data['name'],
          'sprite': getSpriteUrl(int.parse(identifier)),
          'types': data['types'],  // Include types for immediate access
          'stats': data['stats'],  // Include stats for immediate access
        };
        _pokemonCache[identifier] = result;
        return result;
      }
    } catch (e) {
      print('Error fetching Pokemon #$identifier: $e');
    }
    return null;
  }

  // Add missing fetchPokemon method
  Future<Map<String, dynamic>?> fetchPokemon(String identifier) async {
    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$identifier'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching Pokemon data: $e');
    }
    return null;
  }
}