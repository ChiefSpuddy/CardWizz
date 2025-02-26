import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tcg_card.dart';
import '../utils/image_utils.dart';

class TcgdexApiService {
  static const String baseUrl = 'https://www.tcgdex.net/v2';
  
  // Get all Japanese sets
  Future<List<Map<String, dynamic>>> getJapaneseSets() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/jp/sets'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Process the sets
        final List<Map<String, dynamic>> processedSets = [];
        for (final set in data) {
          if (set is Map<String, dynamic>) {
            final setId = set['id'] as String?;
            if (setId != null) {
              // Add logo URL using our utility
              set['logo'] = CardImageUtils.getJapaneseSetLogo(setId);
              processedSets.add(Map<String, dynamic>.from(set));
            }
          }
        }
        
        return processedSets;
      } else {
        throw Exception('Failed to load Japanese sets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching Japanese sets: $e');
      return [];
    }
  }
  
  // Search for Japanese set
  Future<Map<String, dynamic>> searchJapaneseSet(String query) async {
    try {
      // First get all sets
      final sets = await getJapaneseSets();
      
      // Filter by name or ID
      final normalizedQuery = query.toLowerCase().trim();
      final filteredSets = sets.where((set) {
        final name = (set['name'] as String? ?? '').toLowerCase();
        final id = (set['id'] as String? ?? '').toLowerCase();
        
        return name.contains(normalizedQuery) || id.contains(normalizedQuery);
      }).toList();
      
      // Use correct method
      for (var set in filteredSets) {
        final setId = set['id']?.toString() ?? '';
        if (setId.isNotEmpty) {
          set['logo'] = CardImageUtils.getJapaneseSetLogo(setId);
        }
      }
      
      // Format result similar to Pokemon API
      return {
        'data': filteredSets.map((setData) {
          return {
            'id': setData['id'],
            'name': setData['name'],
            'series': setData['serie'],
            'printedTotal': setData['cardCount'] ?? 0,
            'total': setData['cardCount'] ?? 0,
            'releaseDate': setData['releaseDate'],
            'images': {
              'symbol': setData['logo'] ?? CardImageUtils.getJapaneseSetLogo(setData['id']),
              'logo': setData['logo'] ?? CardImageUtils.getJapaneseSetLogo(setData['id']),
            },
            'logo': setData['logo'] ?? CardImageUtils.getJapaneseSetLogo(setData['id']),
          };
        }).toList(),
      };
    } catch (e) {
      print('Error searching Japanese sets: $e');
      return {'data': []};
    }
  }
}
