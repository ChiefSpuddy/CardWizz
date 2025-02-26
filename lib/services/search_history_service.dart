import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryService {
  static const _key = 'recent_searches';
  static const _maxSearches = 20;
  late SharedPreferences _prefs;
  List<Map<String, String>> _searches = [];

  SearchHistoryService._create(SharedPreferences prefs) {
    _prefs = prefs;
    _loadSearches();
  }

  static Future<SearchHistoryService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SearchHistoryService._create(prefs);
  }

  void _loadSearches() {
    final jsonString = _prefs.getString(_key);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      _searches = List<Map<String, String>>.from(
        decoded.map((search) => Map<String, String>.from(search)),
      );
    }
  }

  void _saveSearches() {
    final jsonString = jsonEncode(_searches);
    _prefs.setString(_key, jsonString);
  }

  List<Map<String, String>> getRecentSearches() {
    return List.from(_searches);
  }

  void addSearch(String query, {String? imageUrl}) {
    // Remove existing same query to avoid duplicates
    _searches.removeWhere((search) => search['query'] == query);
    
    // Add new search at the beginning
    _searches.insert(0, {
      'query': query,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    
    // Ensure we don't exceed the maximum allowed searches
    if (_searches.length > _maxSearches) {
      _searches = _searches.sublist(0, _maxSearches);
    }
    
    _saveSearches();
  }

  // Add this method to remove a specific search
  void clearSearch(String query) {
    _searches.removeWhere((search) => search['query'] == query);
    _saveSearches();
  }

  void clearHistory() {
    _searches.clear();
    _saveSearches();
  }
}
