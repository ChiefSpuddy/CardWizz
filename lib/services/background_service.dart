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
    print('Starting price refresh...');
    
    try {
      final cards = await _storage.getCards();
      print('Found ${cards.length} cards to update');

      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        final currentPrice = card.price;
        
        // Get card details first, then extract price
        final cardDetails = await _api.getCardById(card.id);
        final newPrice = cardDetails?['cardmarket']?['prices']?['averageSellPrice'] as double?;
        
        print('Card: ${card.name}');
        print('Old price: $currentPrice');
        print('New price: $newPrice');
        print('History before: ${card.priceHistory.length} entries');

        if (newPrice != null && newPrice != currentPrice) {
          final updatedCard = card.updatePrice(newPrice);
          print('History after: ${updatedCard.priceHistory.length} entries');
          await _storage.updateCard(updatedCard);
        }

        // Notify progress
        _storage.notifyPriceUpdateProgress(i + 1, cards.length);
      }

      print('Price refresh completed');
      _storage.notifyPriceUpdateComplete(cards.length);

      // Recalculate portfolio history
      await _storage.recalculatePortfolioHistory();

    } catch (e) {
      print('Error during price refresh: $e');
      rethrow;
    }
  }

  Future<DateTime?> getLastUpdateTime() async {
    return _lastUpdateTime;
  }

  void dispose() {
    _updateTimer?.cancel();
  }

}
