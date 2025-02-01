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
  static const Duration minUpdateInterval = Duration(hours: 6);  // Add this line
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
    _updateTimer = Timer.periodic(_updateInterval, (_) => _checkAndUpdate());
    BackgroundFetch.start();
  }

  void stopPriceUpdates() {
    _isEnabled = false;
    _updateTimer?.cancel();
    _updateTimer = null;
    BackgroundFetch.stop();
  }

  Future<void> _checkAndUpdate() async {
    final lastUpdate = await getLastUpdateTime();
    final now = DateTime.now();
    
    if (lastUpdate == null || now.difference(lastUpdate) >= _updateInterval) {
      await refreshPrices();
    }
  }

  // Add manual refresh method
  Future<void> refreshPrices() async {
    final lastUpdate = await getLastUpdateTime();
    final now = DateTime.now();
    
    // Don't update if last update was too recent
    if (lastUpdate != null && 
        now.difference(lastUpdate) < minUpdateInterval) {
      print('Skipping price update - too soon since last update');
      return;
    }

    try {
      final cards = await _storageService.getCards();
      print('Starting price update for ${cards.length} cards');
      var updatedCount = 0;

      for (final card in cards) {
        try {
          final details = await _apiService.getCardDetails(card.id);
          if (details != null && details['cardmarket'] != null) {
            final newPrice = details['cardmarket']['prices']?['averageSellPrice'] as double?;
            if (newPrice != null && newPrice != card.price) {
              final updatedCard = card.copyWith(price: newPrice);
              updatedCard.addPricePoint(newPrice);
              await _storageService.updateCard(updatedCard);
              updatedCount++;
              print('Updated price for ${card.name}: ${card.price} -> $newPrice');
            }
          }
        } catch (e) {
          print('Error updating price for card ${card.id}: $e');
        }
        
        // Add delay between requests to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('Updated prices for $updatedCount cards');
      await setLastUpdateTime(now);
    } catch (e) {
      print('Error during price update: $e');
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

  Future<void> setLastUpdateTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateKey, time.millisecondsSinceEpoch);
  }

  void dispose() {
    stopPriceUpdates();
  }
}
