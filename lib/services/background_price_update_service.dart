import 'dart:async';
import 'storage_service.dart';
import 'tcg_api_service.dart';
import 'dialog_manager.dart';  // Add this import

class BackgroundPriceUpdateService {
  final StorageService _storageService;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _lastUpdateTime;
  bool _isRefreshing = false;
  bool _cancelled = false;

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

  void cancelRefresh() {
    _cancelled = true;
  }

  Future<void> refreshPrices() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _cancelled = false;
    
    try {
      final apiService = TcgApiService();
      final cards = await _storageService.getCards();
      
      // Start with 0 progress
      _storageService.notifyPriceUpdateProgress(0, cards.length);
      
      double totalValue = 0;
      
      for (var i = 0; i < cards.length; i++) {
        if (_cancelled) break;

        final card = cards[i];
        print('🔍 Checking price for ${card.name} (${i + 1}/${cards.length})');
        
        try {
          // Get latest price from API
          final price = await apiService.getCardPrice(card.id);
          
          if (price != null && price != card.price) {
            await _storageService.updateCardPrice(card, price);
            print('✅ Updated price for ${card.name}: ${card.price} -> $price');
          } else {
            print('ℹ️ No price change for ${card.name}');
          }
          
          totalValue += price ?? card.price ?? 0;
          
        } catch (e) {
          print('❌ Error updating price for ${card.name}: $e');
        }

        // Show progress for current card
        _storageService.notifyPriceUpdateProgress(i + 1, cards.length);
        
        // Small delay to prevent API rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (!_cancelled) {
        // Save final portfolio value
        await _storageService.savePortfolioValue(totalValue);
        _lastUpdateTime = DateTime.now();
        await _saveLastUpdateTime();
        
        // Wait a moment for UI to catch up
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Show final completion state
        _storageService.notifyPriceUpdateProgress(cards.length, cards.length);
        
        // Notify completion after a delay
        await Future.delayed(const Duration(seconds: 1));
        _storageService.notifyPriceUpdateComplete(0);
      }
      
    } catch (e) {
      print('Error refreshing prices: $e');
      _storageService.notifyPriceUpdateComplete(-1);
    } finally {
      _isRefreshing = false;
      _cancelled = false;
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

  Future<void> updatePrices() async {
    try {
      final cards = await _storageService.getCards();
      DialogManager.instance.hideDialog(); // Now DialogManager is properly imported
      
      for (var i = 0; i < cards.length; i++) {
        DialogManager.instance.showPriceUpdateDialog(i + 1, cards.length);
        // ...rest of update logic...
      }
      
      // Show completion for a moment before hiding
      await Future.delayed(const Duration(seconds: 2));
      DialogManager.instance.hideDialog();
      
    } catch (e) {
      print('Error updating prices: $e');
      DialogManager.instance.hideDialog();
    }
  }
}
