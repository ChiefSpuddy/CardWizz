import 'dart:async';
import 'storage_service.dart';
import 'tcg_api_service.dart';

class BackgroundPriceUpdateService {
  final StorageService _storageService;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _lastUpdateTime;
  bool _isRefreshing = false;

  BackgroundPriceUpdateService(this._storageService);

  Future<void> initialize() async {
    // Perform any necessary initialization tasks here
    print('BackgroundPriceUpdateService initialized');
  }

  void startPriceUpdates() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(hours: 6), (timer) {
      _updatePrices();
    });
    print('Background price updates started');
  }

  void stopPriceUpdates() {
    _timer?.cancel();
    _isRunning = false;
    print('Background price updates stopped');
  }

  Future<void> _updatePrices() async {
    print('Updating prices in the background...');
    try {
      final apiService = TcgApiService();
      final cards = await _storageService.getCards();
      print('Found ${cards.length} cards to update');

      for (final card in cards) {
        try {
          print('Updating price for ${card.name} (ID: ${card.id})');
          final cardDetails = await apiService.getCardById(card.id);

          if (cardDetails == null) {
            print('❌ Could not retrieve card details for ${card.name}');
            continue; // Skip to the next card
          }

          final newPrice = cardDetails?['cardmarket']?['prices']?['averageSellPrice'] as double?;

          if (newPrice != null && newPrice != card.price) {
            print('✅ New price found for ${card.name}: $newPrice (Old: ${card.price})');
            // Add price history point
            await _storageService.addPriceHistoryPoint(card.id, newPrice, DateTime.now());

            // Update card price
            await _storageService.updateCardPrice(card, newPrice);
            print('✅ Updated price for ${card.name} to $newPrice');
          } else {
            print('ℹ️ No price change for ${card.name}');
          }
        } catch (e) {
          print('❌ Error updating price for ${card.name}: $e');
        }
      }
      print('Background price update complete.');
      _lastUpdateTime = DateTime.now();
    } catch (e) {
      print('❌ Error during price refresh: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
  }

  bool get isEnabled => _isRunning;

  Future<DateTime?> getLastUpdateTime() async {
    return _lastUpdateTime;
  }

  Future<void> refreshPrices() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    try {
      final cards = await _storageService.getCards();
      DateTime lastUpdate = DateTime.now();
      int batchSize = 0;
      
      for (var i = 0; i < cards.length; i++) {
        final card = cards[i];
        batchSize++;
        
        // Only notify every 5 cards or 500ms, whichever comes first
        final now = DateTime.now();
        if (batchSize >= 5 || now.difference(lastUpdate) >= const Duration(milliseconds: 500)) {
          _storageService.notifyPriceUpdateProgress(i + 1, cards.length);
          lastUpdate = now;
          batchSize = 0;
        }
        
        print('🔍 Checking price for ${card.name} (${i + 1}/${cards.length})');
        final newPrice = await TcgApiService().fetchCardPrice(card.id);
        
        if (newPrice != null) {
          print('💰 Found price for ${card.name}: ${card.price} -> $newPrice');
          if (newPrice != card.price) {
            await _storageService.updateCardPrice(card, newPrice);
            print('✅ Updated price for ${card.name}');
            
            // Add price history point right after price update
            await _storageService.addPriceHistoryPoint(card.id, newPrice, DateTime.now());
          } else {
            print('ℹ️ No price change for ${card.name}');
          }
        } else {
          print('❌ Failed to get price for ${card.name}');
        }
      }
      
      // Final update
      _storageService.notifyPriceUpdateProgress(cards.length, cards.length);
      
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _saveLastUpdateTime() async {
    if (_lastUpdateTime != null) {
      await _storageService.setString(
        'last_price_update',
        _lastUpdateTime!.toIso8601String(),
      );
    }
  }
}
