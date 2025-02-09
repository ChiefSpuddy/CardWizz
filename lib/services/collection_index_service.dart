import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CollectionIndexService {
  Map<String, int> _cardNumbers = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final String jsonString = await rootBundle.loadString('assets/names.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final namesData = data['names'] as Map<String, dynamic>;
    
    _cardNumbers = Map.fromEntries(
      namesData.entries.map((e) => MapEntry(
        normalizeCardName(e.value as String),
        int.parse(e.key),
      )),
    );
    
    _isInitialized = true;
  }

  Future<List<String>> loadSeriesNames(int start, int end) async {
    List<String> numbers = [];
    for (int i = start; i <= end; i++) {
      numbers.add('Card ${i.toString().padLeft(3, '0')}');
    }
    return numbers;
  }

  Future<List<String>> loadGenerationNames(int start, int end) async {
    if (!_isInitialized) await initialize();
    
    final String jsonString = await rootBundle.loadString('assets/names.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final namesData = data['names'] as Map<String, dynamic>;
    
    List<String> names = [];
    for (int i = start; i <= end; i++) {
      final name = namesData[i.toString()];
      if (name != null) {
        names.add(name);
      }
    }
    return names;
  }

  String _stripCardVariants(String name) {
    return name.toLowerCase()
      .replaceAll(RegExp(r'\s*(ex|gx|v|vmax|vstar|★|\*)\b'), '')
      .replaceAll(RegExp(r'alolan\s+'), '')  // Handle regional variants
      .replaceAll(RegExp(r'galarian\s+'), '')
      .replaceAll(RegExp(r'hisuian\s+'), '')
      .trim();
  }

  int getCardNumber(String name) {
    if (!_isInitialized) {
      initialize();
      return 0;
    }

    // Add common special cases
    final specialCases = {
      'lugia': 249,
      'umbreon': 197,
      'snorlax': 143,
      'kangaskhan': 115,
      'latias': 380,
      'hydreigon': 635,
      'exeggutor': 103,
      // Add more special cases as needed
    };

    // Clean the name first
    final baseName = _stripCardVariants(name);
    
    // Check special cases first
    for (final entry in specialCases.entries) {
      if (baseName.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try exact match from card numbers map
    final number = _cardNumbers[normalizeCardName(baseName)];
    if (number != null) {
      return number;
    }

    // Try to find partial match
    for (final entry in _cardNumbers.entries) {
      if (baseName.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return 0;  // Return 0 if no match found
  }

  Future<Map<String, dynamic>> getGenerationStats(int startNum, int endNum) async {
    if (startNum == null || endNum == null) {
      return {
        'uniqueCards': 0,
        'cardCount': 0,
        'cardUrls': <String, String>{},  // Changed from spriteUrls to cardUrls
      };
    }
    return {
      'uniqueCards': 0,
      'cardCount': 0,
      'cardUrls': <String, String>{},
    };
  }

  // Add helper method for getting card names
  String getCardName(int number) {
    return 'Card ${number.toString().padLeft(3, '0')}';
  }

  String normalizeCardName(String name) {
    // Handle special cases
    final specialCases = {
      'mr mime': 'mr-mime',
      'mime jr': 'mime-jr',
      'farfetchd': 'farfetch\'d',
    };

    String normalized = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
    
    return specialCases[normalized] ?? normalized;
  }

  String normalizeSearchQuery(String name) {
    String normalized = normalizeCardName(name);
    
    // Handle special character display cases
    final displayCases = {
      'mr-mime': 'Mr. Mime',
      'mime-jr': 'Mime Jr.',
      'farfetchd': 'Farfetch\'d',
    };
    
    return displayCases[normalized] ?? 
           normalized.split('-')
                    .map((part) => part[0].toUpperCase() + part.substring(1))
                    .join(' ');
  }

  int? getNumberFromName(String name) {
    if (!_isInitialized) return null;
    return _cardNumbers[normalizeCardName(name)];
  }
}
