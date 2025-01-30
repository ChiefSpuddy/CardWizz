import 'dart:convert';
import 'package:flutter/services.dart';
import 'poke_api_service.dart';

class DexNamesService {
  final _pokeApiService = PokeApiService();
  Map<int, String> _dexMap = {};  // Change to map for O(1) lookup
  bool _isLoaded = false;

  // Add cached generation ranges
  final Map<int, List<String>> _generationCache = {};

  Future<List<String>> loadDexNames() async {
    if (_isLoaded) return _dexMap.values.toList();
    try {
      // Fetch first 386 Pokémon (Gen 1-3)
      for (int i = 1; i <= 386; i++) {
        final data = await _pokeApiService.fetchPokemon(i.toString());
        if (data != null) {
          _dexMap[i] = _capitalize(data['name']);
        }
      }
      _isLoaded = true;
      return _dexMap.values.toList();
    } catch (e) {
      print('Error loading dex names: $e');
      return [];
    }
  }

  Future<List<String>> loadGenerationNames(int start, int end) async {
    final key = start * 1000 + end;
    if (_generationCache.containsKey(key)) {
      return _generationCache[key]!;
    }

    try {
      final names = <String>[];
      final futures = List.generate(
        end - start + 1,
        (i) => _pokeApiService.fetchBasicData((start + i).toString())
      );

      final results = await Future.wait(futures);
      
      for (var i = 0; i < results.length; i++) {
        final data = results[i];
        if (data != null) {
          final name = _capitalize(data['name']);
          names.add(name);
          _dexMap[start + i] = name;  // Store in map for reverse lookup
        }
      }
      
      _generationCache[key] = names;
      return names;
    } catch (e) {
      print('Error loading generation names: $e');
      return [];
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Update to use map lookup
  int getDexNumber(String pokemonName) {
    try {
      return _dexMap.entries
          .firstWhere((entry) => entry.value == pokemonName)
          .key;
    } catch (e) {
      print('Error getting dex number for $pokemonName: $e');
      return 0;
    }
  }
}
