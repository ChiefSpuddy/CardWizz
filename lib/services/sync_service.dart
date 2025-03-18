import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart' as wm;
import 'package:background_fetch/background_fetch.dart' as bf;
import '../services/storage_service.dart';
import '../services/logging_service.dart';

/// Service to handle background sync operations
class SyncService {
  static const String _syncTaskKey = 'com.sammay.cardwizz.synctask';
  static const Duration _syncInterval = Duration(hours: 3);
  
  /// Initialize background sync capability
  static Future<void> initialize(StorageService storageService) async {
    try {
      // Initialize Workmanager (Android)
      await wm.Workmanager().initialize(
        _callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      
      // Register periodic task
      await wm.Workmanager().registerPeriodicTask(
        _syncTaskKey,
        'background_sync',
        frequency: _syncInterval,
        constraints: wm.Constraints(
          networkType: wm.NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
      
      // Initialize BackgroundFetch (iOS)
      await bf.BackgroundFetch.configure(
        bf.BackgroundFetchConfig(
          minimumFetchInterval: (_syncInterval.inMinutes / 60).round(),
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiredNetworkType: bf.NetworkType.ANY,
        ),
        _onBackgroundFetch,
      );
      
      LoggingService.debug('SyncService initialized successfully');
    } catch (e) {
      LoggingService.debug('Error initializing SyncService: $e');
    }
  }
  
  /// Stop all background sync tasks
  static Future<void> stop() async {
    await wm.Workmanager().cancelAll();
    await bf.BackgroundFetch.stop();
    LoggingService.debug('SyncService stopped');
  }
}

/// Background fetch handler for iOS
void _onBackgroundFetch(String taskId) async {
  LoggingService.debug('iOS background fetch triggered');
  // TODO: Implement actual sync logic
  
  // IMPORTANT: You must call finish() when done
  bf.BackgroundFetch.finish(taskId);
}

/// Workmanager callback dispatcher for Android (must be top-level function)
@pragma('vm:entry-point')
void _callbackDispatcher() {
  wm.Workmanager().executeTask((task, inputData) async {
    LoggingService.debug('Android background task triggered: $task');
    // TODO: Implement actual sync logic
    return true;
  });
}
