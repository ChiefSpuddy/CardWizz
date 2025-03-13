import '../services/logging_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:dio/dio.dart';  // Add this import

class PokeApiService {
  final _dio = Dio();  // Add this line
  static const int _maxConcurrentRequests = 20;  // Increased for better performance
  final Map<String, String> _spriteCache = {};
  final Map<String, Map<String, dynamic>> _pokemonCache = {};
  final _cacheManager = DefaultCacheManager();
  final Map<String, Map<String, dynamic>> _speciesCache = {};

  // Optimize sprite URL handling with CDN
  String getSpriteUrl(int dexNum) {
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$dexNum.png';
  }

  // Add efficient batch loading
  Future<List<Map<String, dynamic>>> fetchPokemonBatch(List<int> dexNumbers) async {
    final results = <Map<String, dynamic>>[];
    final uncachedNumbers = dexNumbers.where(
      (num) => !_pokemonCache.containsKey(num.toString())
    ).toList();
    
    // Add cached results first
    results.addAll(
      dexNumbers
          .where((num) => _pokemonCache.containsKey(num.toString()))
          .map((num) => _pokemonCache[num.toString()]!)
    );

    // Process uncached in smaller batches
    for (var i = 0; i < uncachedNumbers.length; i += _maxConcurrentRequests) {
      final batch = uncachedNumbers.skip(i).take(_maxConcurrentRequests);
      final futures = batch.map((dexNum) => _fetchAndCacheBasicData(dexNum.toString()));
      final responses = await Future.wait(futures);
      results.addAll(responses.whereType<Map<String, dynamic>>());
    }
    
    return results;
  }

  Future<Map<String, dynamic>?> _fetchAndCacheBasicData(String identifier) async {
    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$identifier'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = {
          'name': data['name'],
          'sprite': getSpriteUrl(int.parse(identifier)),
          'types': data['types'],
          'stats': data['stats'],
        };
        _pokemonCache[identifier] = result;
        
        // Pre-cache sprite image
        _cacheManager.downloadFile(result['sprite']);
        
        return result;
      }
    } catch (e) {
      LoggingService.debug('Error fetching Pokemon #$identifier: $e');
    }
    return null;
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
      LoggingService.debug('Error fetching Pokemon #$identifier: $e');
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
      LoggingService.debug('Error fetching Pokemon data: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchSpeciesData(int dexNum) async {
    final identifier = dexNum.toString();
    if (_speciesCache.containsKey(identifier)) {
      return _speciesCache[identifier];
    }

    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$identifier'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Get English flavor text entries
        final flavorTexts = (data['flavor_text_entries'] as List)
            .where((entry) => entry['language']['name'] == 'en')
            .map((entry) => entry['flavor_text'].toString()
                .replaceAll('\n', ' ')
                .replaceAll('\f', ' '))
            .toList();

        final result = {
          'flavor_text': flavorTexts.isNotEmpty ? flavorTexts.first : null,
          'color': data['color']['name'],
          'habitat': data['habitat']?['name'],
          'generation': data['generation']['name'],
        };
        
        _speciesCache[identifier] = result;
        return result;
      }
    } catch (e) {
      LoggingService.debug('Error fetching species data for #$identifier: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchCard(String pokemonName) async {
    try {
      final response = await _dio.get(
        'https://api.pokemontcg.io/v2/cards',
        queryParameters: {
          'q': 'name:$pokemonName',
          'pageSize': 1,
          'orderBy': 'set.releaseDate'  // Get the newest card
        },
      );
      
      if (response.data['data']?.isNotEmpty) {
        return response.data['data'][0];
      }
      return null;
    } catch (e) {
      LoggingService.debug('Error fetching card for $pokemonName: $e');
      return null;
    }
  }
}