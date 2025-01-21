import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryService {
  static const String _key = 'recent_searches';
  static const int maxSearches = 10;
  final SharedPreferences _prefs;

  SearchHistoryService(this._prefs);

  static Future<SearchHistoryService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SearchHistoryService(prefs);
  }

  List<Map<String, String>> getRecentSearches() {
    try {
      final jsonStr = _prefs.getString(_key);
      if (jsonStr == null) return [];

      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList
          .map((item) => Map<String, String>.from(item))
          .toList();
    } catch (e) {
      print('Error loading search history: $e');
      return [];
    }
  }

  Future<void> addSearch(String query, {String? imageUrl}) async {
    final searches = getRecentSearches();
    
    // Remove if exists
    searches.removeWhere((s) => s['query'] == query);
    
    // Add to front
    searches.insert(0, {
      'query': query,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    
    // Keep only recent ones
    if (searches.length > maxSearches) {
      searches.removeRange(maxSearches, searches.length);
    }
    
    // Save as single JSON string
    await _prefs.setString(_key, json.encode(searches));
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_key);
  }
}
