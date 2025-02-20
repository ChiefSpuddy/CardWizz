import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  static const String _cacheDir = 'card_images';
  
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static final _cacheManager = CacheManager(
    Config(
      'pokemon_cards_cache',
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 2000,
      repo: JsonCacheInfoRepository(databaseName: 'pokemon_cards_cache'),
      fileService: HttpFileService(),
    ),
  );

  Future<String?> getCachedImagePath(String url) async {
    try {
      // Try to get from permanent cache first
      final permanentPath = await _getPermanentCachePath(url);
      if (await File(permanentPath).exists()) {
        return permanentPath;
      }

      // Try to get from cache manager
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        // Copy to permanent cache
        await _copyToPermanentCache(fileInfo.file, url);
        return fileInfo.file.path;
      }

      return null;
    } catch (e) {
      print('Error getting cached image: $e');
      return null;
    }
  }

  Future<void> cacheImage(String url) async {
    try {
      // Download and cache the image
      final file = await _cacheManager.getSingleFile(url);
      if (await file.exists()) {
        // Copy to permanent cache
        await _copyToPermanentCache(file, url);
      }
    } catch (e) {
      print('Error caching image: $e');
    }
  }

  Future<String> _getPermanentCachePath(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final hash = sha256.convert(utf8.encode(url)).toString();
    return '${dir.path}/$_cacheDir/$hash.png';
  }

  Future<void> _copyToPermanentCache(File file, String url) async {
    try {
      final permanentPath = await _getPermanentCachePath(url);
      final permanentFile = File(permanentPath);
      
      // Create directory if it doesn't exist
      await permanentFile.parent.create(recursive: true);
      
      // Copy file to permanent cache
      if (!await permanentFile.exists()) {
        await file.copy(permanentPath);
      }
    } catch (e) {
      print('Error copying to permanent cache: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/$_cacheDir');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
