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
  static const Duration updateInterval = Duration(hours: 12);
  
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
        now.difference(_lastUpdateTime!) < updateInterval) {
      return;  // Not enough time has passed
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
    
    // Notify progress start
    _storage.notifyPriceUpdateProgress(0, total);

    final updatedCards = <TcgCard>[];
    var updatedCount = 0;

    for (final card in cards) {
      try {
        progress++;
        _storage.notifyPriceUpdateProgress(progress, total);

        // Get prices from both APIs
        final tcgDetails = await _api.getCardDetails(card.id);
        final tcgPrice = tcgDetails?['cardmarket']?['prices']?['averageSellPrice'];
        
        // Get eBay price as backup/comparison
        double? ebayPrice;
        try {
          ebayPrice = await _ebayApi.getAveragePrice(
            card.name,
            setName: card.setName,
          );
          print('eBay price for ${card.name}: $ebayPrice');
        } catch (e) {
          print('eBay API error for ${card.name}: $e');
        }

        // Use TCG price if available, otherwise use eBay price
        final newPrice = tcgPrice ?? ebayPrice;
        if (newPrice == null) {
          print('No price available for ${card.name}');
          continue;
        }

        // Add both prices to history for comparison
        if (tcgPrice != null) {
          card.priceHistory.add(PricePoint(
            price: tcgPrice,
            timestamp: DateTime.now(),
            source: 'TCG',
          ));
        }
        if (ebayPrice != null) {
          card.priceHistory.add(PricePoint(
            price: ebayPrice,
            timestamp: DateTime.now(),
            source: 'eBay',
          ));
        }

        final currentPrice = card.price ?? 0;
        if (currentPrice != newPrice || card.priceHistory.isEmpty) {
          final newHistory = List<PricePoint>.from(card.priceHistory);
          newHistory.add(PricePoint(
            price: newPrice,
            timestamp: DateTime.now(),
          ));

          // Keep only last 30 days of history
          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          newHistory.removeWhere((p) => p.timestamp.isBefore(thirtyDaysAgo));

          final updatedCard = TcgCard(
            id: card.id,
            name: card.name,
            imageUrl: card.imageUrl,
            price: newPrice,
            number: card.number,
            setName: card.setName,
            rarity: card.rarity,
            priceHistory: newHistory,
            lastPriceUpdate: DateTime.now(),
            set: card.set,
          );

          updatedCards.add(updatedCard);
          updatedCount++;
          print('📊 Price change for ${card.name}: ${currentPrice.toStringAsFixed(2)} -> ${newPrice.toStringAsFixed(2)}');
        }
      } catch (e) {
        print('Error updating price for ${card.name}: $e');
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Notify completion
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
