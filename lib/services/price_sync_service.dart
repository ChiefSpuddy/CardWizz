import 'dart:async';
import 'dart:io' show Platform;
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';
import '../models/tcg_card.dart';

class PriceSyncService {
  static const String taskName = 'syncPrices';
  static const String apiBaseUrl = 'https://api.pokemontcg.io/v2';
  static const String apiKey = 'eebb53a0-319a-4231-9244-fd7ea48b5d2c';

  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _initializeAndroid();
    }
    // iOS background fetch is handled by the system automatically
  }

  static Future<void> _initializeAndroid() async {
    await Workmanager().initialize(callbackDispatcher);
    await scheduleDailySync();
  }

  static Future<void> scheduleDailySync() async {
    if (Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        taskName,
        taskName,
        frequency: const Duration(hours: 24),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    }
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == taskName) {
        final storage = await StorageService.init();
        await _syncPrices(storage);
      }
      return true;
    });
  }

  static Future<void> _syncPrices(StorageService storage) async {
    try {
      print('Starting price sync at ${DateTime.now()}');
      final cards = await storage.getCards();
      
      var updatedCount = 0;
      for (final card in cards) {
        final newPrice = await _fetchLatestPrice(card.id);
        if (newPrice != null && newPrice != card.price) {
          // Add price history before updating current price
          await storage.addPriceHistoryPoint(
            card.id, 
            card.price ?? 0,
            DateTime.now(),
          );
          
          // Update current price
          await storage.updateCardPrice(card.id, newPrice);
          updatedCount++;
          print('Updated price for ${card.name}: ${card.price} -> $newPrice');
        }
      }
      
      // Update last sync time
      await storage.backgroundService?.setLastUpdateTime(DateTime.now());
      
      print('Completed price sync. Updated $updatedCount cards');
    } catch (e) {
      print('Error during price sync: $e');
      rethrow;  // Rethrow to handle in UI
    }
  }

  static Future<double?> _fetchLatestPrice(String cardId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/cards/$cardId'),
        headers: {'X-Api-Key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data']['cardmarket']['prices']['averageSellPrice'] as num?)?.toDouble();
      }
    } catch (e) {
      print('Error fetching price for card $cardId: $e');
    }
    return null;
  }

  // Manual sync trigger for testing
  static Future<void> triggerManualSync() async {
    final storage = await StorageService.init();
    await _syncPrices(storage);
  }

  // Add this method for manual testing
  static Future<String> testSync() async {
    final storage = await StorageService.init();
    final before = DateTime.now();
    await _syncPrices(storage);
    final duration = DateTime.now().difference(before);
    return 'Sync completed in ${duration.inSeconds} seconds';
  }
}
