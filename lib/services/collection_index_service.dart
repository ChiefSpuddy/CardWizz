import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// Add this extension at the top of the file
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class CollectionIndexService {
  Map<String, int> _nameToNumber = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final String jsonString = await rootBundle.loadString('assets/names.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final namesData = data['names'] as Map<String, dynamic>;
    
    _nameToNumber = Map.fromEntries(
      namesData.entries.map((e) => MapEntry(
        normalizeCreatureName(e.value as String),
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

  int getCardNumber(String cardName) {
    final match = RegExp(r'Card (\d+)').firstMatch(cardName);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  int getDexNumber(String name) {
    // Use look up from names.json data
    // This will need to be implemented based on your data structure
    return int.tryParse(name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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

  String normalizeCreatureName(String name) {
    // Handle special cases
    final specialCases = {
      'nidoran♀': 'nidoran-f',
      'nidoran♂': 'nidoran-m',
      'nidoran f': 'nidoran-f',
      'nidoran m': 'nidoran-m',
      'farfetchd': 'farfetchd',
      'mr mime': 'mr-mime',
      'mime jr': 'mime-jr',
      'type null': 'type-null',
    };

    String normalized = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
    
    return specialCases[normalized] ?? normalized;
  }

  String normalizeSearchQuery(String name) {
    String normalized = normalizeCreatureName(name);
    
    // Handle special character display cases
    final displayCases = {
      'nidoran-f': 'Nidoran♀',
      'nidoran-m': 'Nidoran♂',
      'farfetchd': 'Farfetch\'d',
      'mr-mime': 'Mr. Mime',
      'mime-jr': 'Mime Jr.',
      'type-null': 'Type: Null',
    };
    
    if (displayCases.containsKey(normalized)) {
      return displayCases[normalized]!;
    }
    
    return normalized
        .split('-')
        .map((part) => part.capitalize())
        .join(' ');
  }

  int? getNumberFromName(String name) {
    if (!_isInitialized) return null;
    return _nameToNumber[normalizeCreatureName(name)];
  }
}
