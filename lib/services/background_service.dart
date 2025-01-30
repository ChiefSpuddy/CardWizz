import 'dart:async';
import 'package:background_fetch/background_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Fix import
import '../services/storage_service.dart';
import '../services/tcg_api_service.dart';
import '../models/tcg_card.dart';

enum NetworkType {
  ANY,
  UNMETERED,
  NOT_ROAMING,
}

class BackgroundService {
  static const Duration _updateInterval = Duration(hours: 24);
  static const String _lastUpdateKey = 'last_price_update';
  final StorageService _storageService;
  final TcgApiService _apiService;
  Timer? _updateTimer;
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  BackgroundService(this._storageService, this._apiService) {
    _initBackgroundFetch();
  }

  Future<void> _initBackgroundFetch() async {
    try {
      await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 720, // 12 hours
          stopOnTerminate: false,
          enableHeadless: true,
          requiresBatteryNotLow: true,
          requiresCharging: false,
          requiresStorageNotLow: true,
        ),
        _onBackgroundFetch,
      );
      
      await BackgroundFetch.registerHeadlessTask(_onBackgroundFetch);
    } catch (e) {
      print('Error configuring background fetch: $e');
    }
  }

  static void _onBackgroundFetch(String taskId) async {
    print('[BackgroundFetch] Event received: $taskId');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Only update if more than 24 hours have passed
      if (now - lastUpdate >= const Duration(hours: 24).inMilliseconds) {
        // Re-initialize services for background task
        final storage = await StorageService.init(null);
        final apiService = TcgApiService();
        final instance = BackgroundService(storage, apiService);
        
        await instance._updatePrices();
        await prefs.setInt(_lastUpdateKey, now);
      }
    } catch (e) {
      print('[BackgroundFetch] Error: $e');
    }
    
    // Required: Signal completion
    BackgroundFetch.finish(taskId);
  }

  void startPriceUpdates() {
    _isEnabled = true;
    _updateTimer?.cancel();
    _checkAndUpdate();
    BackgroundFetch.start();
  }

  void stopPriceUpdates() {
    _isEnabled = false;
    _updateTimer?.cancel();
    _updateTimer = null;
    BackgroundFetch.stop();
  }

  Future<void> _checkAndUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (now - lastUpdate >= _updateInterval.inMilliseconds) {
      await _updatePrices();
      await prefs.setInt(_lastUpdateKey, now);
    }
  }

  // Add manual refresh method
  Future<void> refreshPrices() async {
    try {
      await _updatePrices();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Manual refresh error: $e');
      rethrow;
    }
  }

  Future<void> _updatePrices() async {
    try {
      final cards = await _storageService.getCards();
      print('Starting price update for ${cards.length} cards');
      
      for (final card in cards) {
        try {
          final updatedCardData = await _apiService.getCardDetails(card.id);
          if (updatedCardData != null) {
            final updatedCard = TcgCard.fromJson(updatedCardData);
            if (updatedCard.price != card.price) {
              await _storageService.saveCard(updatedCard);
              print('Updated price for ${card.name}: ${card.price} -> ${updatedCard.price}');
            }
          }
        } catch (e) {
          print('Error updating card ${card.name}: $e');
          continue;
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      print('Price update completed');
    } catch (e) {
      print('Error during price update: $e');
      rethrow;
    }
  }

  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    return timestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  void dispose() {
    stopPriceUpdates();
  }
}
