class BackgroundService {
  // ...existing code...

  Future<void> refreshPrices() async {
    try {
      final processedCards = <String>{};  // Track processed card IDs
      final cards = await _storage.getCards();
      print('Starting price refresh...');
      print('Found ${cards.length} cards to update');
      var updatedCount = 0;
      final batchSize = 5;
      
      for (var i = 0; i < cards.length; i += batchSize) {
        final batch = cards.sublist(i, min(i + batchSize, cards.length));
        
        for (final card in batch) {
          // Skip if already processed
          if (processedCards.contains(card.id)) continue;
          processedCards.add(card.id);

          print('Processing ${card.name} (${card.id})');
          print('Old price: ${card.price}');

          // Force a fresh API call by bypassing cache
          final response = await _tcgApi._dio.get(
            '/cards/${card.id}',
            options: Options(
              headers: {'X-Api-Key': TcgApiService.apiKey},
              // Force bypass cache
              extra: {'fresh': true},
            ),
          );

          final newPrice = response.data['data']['cardmarket']?['prices']?['averageSellPrice'] as double?;
          print('New price from API: $newPrice');

          if (newPrice != null && newPrice != card.price) {
            print('Updating price: ${card.price} -> $newPrice');
            
            // Add to price history with current timestamp
            await _storage.addPriceHistoryPoint(
              card.id,
              card.price ?? newPrice, // Use current price if available
              DateTime.now(),
            );

            // Update current price
            await _storage.updateCardPrice(card.id, newPrice);
            updatedCount++;
          }
          
          // Add delay between API calls
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Add delay between batches
        if (i + batchSize < cards.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Notify progress (use processedCards.length for accurate count)
        _priceUpdateProgressController.add((processedCards.length, cards.length));
      }

      // Update last sync time and notify completion
      await setLastUpdateTime(DateTime.now());
      _priceUpdateCompleteController.add(updatedCount);
      
      print('Price refresh completed. Updated $updatedCount cards');
    } catch (e) {
      print('Error during price refresh: $e');
      rethrow;
    }
  }

  String _formatTimeDifference(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}
