import 'dart:async';
import 'storage_service.dart';
import 'tcg_api_service.dart';

class BackgroundPriceUpdateService {
  final StorageService _storageService;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _lastUpdateTime;

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
    await _updatePrices();
  }
}
