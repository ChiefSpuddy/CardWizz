import 'dart:convert';
import 'package:flutter/services.dart';
import 'poke_api_service.dart';

class DexNamesService {
  final _pokeApiService = PokeApiService();
  List<String> _dexNames = [];
  bool _isLoaded = false;

  Future<List<String>> loadDexNames() async {
    if (_isLoaded) return _dexNames;
    try {
      // Fetch first 386 Pokémon (Gen 1-3)
      for (int i = 1; i <= 386; i++) {
        final data = await _pokeApiService.fetchPokemon(i.toString());
        if (data != null) {
          _dexNames.add(_capitalize(data['name']));
        }
      }
      _isLoaded = true;
      return _dexNames;
    } catch (e) {
      print('Error loading dex names: $e');
      return [];
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Helper method to get dex number from name
  int getDexNumber(String pokemonName) {
    return _dexNames.indexOf(pokemonName) + 1;
  }
}
