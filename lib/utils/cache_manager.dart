import 'package:shared_preferences/shared_preferences.dart';  // Fix the import
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static final CustomCacheManager _instance = CustomCacheManager._internal();
  factory CustomCacheManager() => _instance;
  CustomCacheManager._internal();

  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  Future<void> set(String key, dynamic value, Duration expiry) async {
    final prefs = await SharedPreferences.getInstance();
    final item = {
      'value': value,
      'expiry': DateTime.now().add(expiry).millisecondsSinceEpoch,
    };
    await prefs.setString(key, jsonEncode(item));
  }

  Future<dynamic> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final item = prefs.getString(key);
    if (item == null) return null;

    final cached = jsonDecode(item);
    final expiry = DateTime.fromMillisecondsSinceEpoch(cached['expiry']);
    
    if (DateTime.now().isAfter(expiry)) {
      await prefs.remove(key);
      return null;
    }

    return cached['value'];
  }

  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    await _cacheManager.removeFile(key);
  }

  // Add method for caching images
  Future<String> getCachedImageUrl(String url) async {
    final file = await _cacheManager.getSingleFile(url);
    return file.path;
  }
}
