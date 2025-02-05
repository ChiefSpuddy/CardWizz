import 'dart:convert';
import 'package:flutter/services.dart';
import 'poke_api_service.dart';

class DexNamesService {
  final _pokeApiService = PokeApiService();
  Map<int, String> _dexMap = {};  // Change to map for O(1) lookup
  bool _isLoaded = false;

  // Add cached generation ranges
  final Map<int, List<String>> _generationCache = {};

  // Add mapping for special cases
  final Map<String, String> _specialNameMappings = {
    'nidoran-f': 'Nidoran♀',
    'nidoran-m': 'Nidoran♂',
    'farfetchd': 'Farfetch\'d',
    'mr-mime': 'Mr. Mime',
    'ho-oh': 'Ho-Oh',
    'mime-jr': 'Mime Jr.',
    // Add more mappings as needed
  };

  // Add generation boundaries for efficient loading
  static const Map<int, (int, int)> _generationBoundaries = {
    1: (1, 151),
    2: (152, 251),
    3: (252, 386),
    4: (387, 493),
    5: (494, 649),
    6: (650, 721),
    7: (722, 809),
    8: (810, 905),
    9: (906, 1008),
  };

  Future<List<String>> loadDexNames() async {
    if (_isLoaded) return _dexMap.values.toList();
    try {
      // Fetch all Pokémon (Gen 1-9)
      for (int i = 1; i <= 1008; i++) {
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
      final batchSize = 50;  // Process in smaller batches
      final names = <String>[];
      
      for (var i = start; i <= end; i += batchSize) {
        final batchEnd = (i + batchSize - 1).clamp(start, end);
        final dexNumbers = List.generate(batchEnd - i + 1, (index) => i + index);
        
        final results = await _pokeApiService.fetchPokemonBatch(dexNumbers);
        
        for (final data in results) {
          if (data != null) {
            final name = _formatPokemonName(data['name']);
            names.add(name);
            _dexMap[i + names.length - 1] = name;
          }
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

  String _formatPokemonName(String name) {
    // Check special mappings first
    if (_specialNameMappings.containsKey(name.toLowerCase())) {
      return _specialNameMappings[name.toLowerCase()]!;
    }

    // Handle hyphenated names
    if (name.contains('-')) {
      return name.split('-')
          .map((part) => _capitalize(part))
          .join('-');
    }

    return _capitalize(name);
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

  // Add method to get generation info
  static (int, int)? getGenerationBoundaries(int genNumber) {
    return _generationBoundaries[genNumber];
  }
}
