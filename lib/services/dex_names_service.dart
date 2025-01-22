import 'dart:convert';
import 'package:flutter/services.dart';

class DexNamesService {
  List<String> _dexNames = [];
  bool _isLoaded = false;

  Future<List<String>> loadDexNames() async {
    if (_isLoaded) return _dexNames;
    try {
      // For now, return first 151 Pokémon
      _dexNames = [
        'Bulbasaur', 'Ivysaur', 'Venusaur', 'Charmander', 'Charmeleon',
        'Charizard', 'Squirtle', 'Wartortle', 'Blastoise', 'Caterpie',
        'Metapod', 'Butterfree', 'Weedle', 'Kakuna', 'Beedrill',
        'Pidgey', 'Pidgeotto', 'Pidgeot', 'Rattata', 'Raticate',
        'Spearow', 'Fearow', 'Ekans', 'Arbok', 'Pikachu',
        // ...add more Pokémon names...
      ];
      _isLoaded = true;
      return _dexNames;
    } catch (e) {
      print('Error loading dex names: $e');
      return [];
    }
  }

  // Helper method to get dex number from name
  int getDexNumber(String pokemonName) {
    return _dexNames.indexOf(pokemonName) + 1;
  }
}
