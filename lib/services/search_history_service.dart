import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryService {
  static const String _key = 'recent_searches';
  static const int maxSearches = 5;
  final SharedPreferences _prefs;

  SearchHistoryService(this._prefs);

  static Future<SearchHistoryService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SearchHistoryService(prefs);
  }

  List<Map<String, dynamic>> getRecentSearches() {
    final String? searchesJson = _prefs.getString(_key);
    if (searchesJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(searchesJson);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      return [];
    }
  }

  Future<void> addSearch(String query, {String? imageUrl}) async {
    if (query.trim().isEmpty) return;

    final searches = getRecentSearches();
    
    // Remove if exists to avoid duplicates
    searches.removeWhere((s) => s['query'] == query);
    
    // Add new search at the beginning
    searches.insert(0, {
      'query': query.trim(),
      'timestamp': DateTime.now().toIso8601String(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    // Keep only the most recent searches
    if (searches.length > maxSearches) {
      searches.removeRange(maxSearches, searches.length);
    }

    await _prefs.setString(_key, json.encode(searches));
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_key);
  }
}
