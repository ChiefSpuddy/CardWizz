import 'dart:async';
import '../services/storage_service.dart';
import '../services/tcg_api_service.dart';
import '../services/ebay_api_service.dart';  // Add this import
import '../models/tcg_card.dart';

class BackgroundService {
  final StorageService _storage;
  final TcgApiService _api;
  final EbayApiService _ebayApi = EbayApiService();  // Re-enable eBay API
  Timer? _updateTimer;
  DateTime? _lastUpdateTime;
  bool _isEnabled = true;
  static const Duration updateInterval = Duration(hours: 6);
  static const Duration minUpdateInterval = Duration(hours: 1);
  
  BackgroundService(this._storage, this._api);

  bool get isEnabled => _isEnabled;

  Future<void> _initializeLastUpdateTime() async {
    final cards = await _storage.getAllCards();
    _lastUpdateTime = cards
        .map((c) => c.lastPriceUpdate)
        .where((date) => date != null)
        .fold<DateTime?>(null, (prev, curr) => 
            prev == null || curr!.isAfter(prev) ? curr : prev);
  }

  Future<void> initialize() async {
    await _initializeLastUpdateTime();
    if (_isEnabled) {
      startPriceUpdates();
    }
  }

  void startPriceUpdates() {
    _isEnabled = true;
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _checkForUpdates();
    });
    // Run initial check
    _checkForUpdates();
  }

  void stopPriceUpdates() {
    _isEnabled = false;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _checkForUpdates() async {
    final now = DateTime.now();
    if (_lastUpdateTime != null && 
        now.difference(_lastUpdateTime!) < minUpdateInterval) {
      return;  // Don't update if less than 1 hour has passed
    }
    
    await refreshPrices();
  }

  Future<void> refreshPrices() async {
    if (!_isEnabled) return;

    print('Starting price refresh...');
    final cards = await _storage.getAllCards();
    if (cards.isEmpty) return;

    var progress = 0;
    final total = cards.length;
    
    _storage.notifyPriceUpdateProgress(0, total);

    final updatedCards = <TcgCard>[];
    var updatedCount = 0;

    for (final card in cards) {
      try {
        progress++;
        _storage.notifyPriceUpdateProgress(progress, total);

        // Get eBay price
        final newPrice = await _ebayApi.getAveragePrice(
          card.name,
          setName: card.setName,
          number: card.number,
        );

        if (newPrice != null) {
          // Always add price to history even if it hasn't changed significantly
          final updatedCard = card.updatePrice(newPrice);
          await _storage.updateCard(updatedCard);
          if ((card.price ?? 0) != newPrice) {
            updatedCount++;
            print('📊 Price change for ${card.name}: ${card.price?.toStringAsFixed(2) ?? "0.00"} -> ${newPrice.toStringAsFixed(2)}');
          }
        }

      } catch (e) {
        print('Error updating price for ${card.name}: $e');
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    _storage.notifyPriceUpdateComplete(updatedCount);
    _lastUpdateTime = DateTime.now();
    print('Price refresh complete. Updated $updatedCount cards.');
  }

  Future<DateTime?> getLastUpdateTime() async {
    return _lastUpdateTime;
  }

  void dispose() {
    _updateTimer?.cancel();
  }

}
