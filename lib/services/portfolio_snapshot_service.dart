import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tcg_card.dart';
import '../services/logging_service.dart';
import '../services/storage_service.dart';
import '../services/chart_service.dart';
import '../utils/card_details_router.dart';

/// Service responsible for managing portfolio value snapshots
/// and scheduling regular updates to track historical value
class PortfolioSnapshotService {
  // Singleton implementation
  static final PortfolioSnapshotService _instance = PortfolioSnapshotService._internal();
  factory PortfolioSnapshotService() => _instance;
  PortfolioSnapshotService._internal();
  
  // Constants
  static const String _lastSnapshotKey = 'last_portfolio_snapshot_timestamp';
  static const Duration _defaultUpdateInterval = Duration(hours: 24);
  
  // Service dependencies
  StorageService? _storageService;
  
  // Status tracking
  bool _isInitialized = false;
  bool _isUpdating = false;
  Timer? _scheduledUpdateTimer;
  
  /// Initialize the service with required dependencies
  Future<void> initialize(StorageService storageService) async {
    if (_isInitialized) return;
    
    _storageService = storageService;
    _isInitialized = true;
    
    // First check if we have cards but no portfolio history yet - if so, force an update
    final cards = await _storageService!.watchCards().first;
    if (cards.isNotEmpty) {
      final portfolioHistoryKey = _storageService!.getUserKey('portfolio_history');
      final portfolioHistoryJson = _storageService!.prefs.getString(portfolioHistoryKey);
      
      if (portfolioHistoryJson == null || portfolioHistoryJson.isEmpty) {
        // We have cards but no history - force create an initial snapshot
        await forceUpdate();
      } else {
        // Otherwise check as normal
        await checkAndUpdateSnapshot();
      }
    } else {
      // No cards, just do the regular check
      await checkAndUpdateSnapshot();
    }
    
    // Set up recurring timer for daily checks
    _scheduledUpdateTimer?.cancel();
    _scheduledUpdateTimer = Timer.periodic(
      const Duration(hours: 6), // Check every 6 hours to ensure we don't miss a day
      (_) => checkAndUpdateSnapshot()
    );
    
    LoggingService.debug('PortfolioSnapshotService initialized');
  }
  
  /// Check if we need to create a new snapshot and do so if needed
  Future<bool> checkAndUpdateSnapshot() async {
    if (!_isInitialized || _isUpdating || _storageService == null) {
      return false;
    }
    
    _isUpdating = true;
    try {
      // Get last snapshot time
      final prefs = await SharedPreferences.getInstance();
      final lastSnapshotTimeString = prefs.getString(_lastSnapshotKey);
      final lastSnapshotTime = lastSnapshotTimeString != null 
          ? DateTime.parse(lastSnapshotTimeString) 
          : null;
      
      final now = DateTime.now();
      
      // If we've never taken a snapshot or it's been more than a day, create one
      if (lastSnapshotTime == null || 
          now.difference(lastSnapshotTime) >= _defaultUpdateInterval) {
        
        // Get current cards
        final cards = await _storageService!.watchCards().first;
        
        // Take snapshot of current portfolio value
        final snapshotTaken = await _takePortfolioSnapshot(cards, now);
        
        if (snapshotTaken) {
          // Update last snapshot time
          await prefs.setString(_lastSnapshotKey, now.toIso8601String());
          LoggingService.debug('New portfolio snapshot created at ${now.toString()}');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      LoggingService.debug('Error in portfolio snapshot service: $e');
      return false;
    } finally {
      _isUpdating = false;
    }
  }
  
  /// Take a snapshot of the current portfolio value and add it to history
  Future<bool> _takePortfolioSnapshot(List<TcgCard> cards, DateTime timestamp, {bool forceCreate = false}) async {
    try {
      if (_storageService == null) return false;
      
      // Calculate total collection value using the consistent method
      final totalValue = await CardDetailsRouter.calculateRawTotalValue(cards);
      
      // Get existing history
      final portfolioHistoryKey = _storageService!.getUserKey('portfolio_history');
      final portfolioHistoryJson = _storageService!.prefs.getString(portfolioHistoryKey);
      
      List<Map<String, dynamic>> historyData = [];
      if (portfolioHistoryJson != null) {
        historyData = List<Map<String, dynamic>>.from(
          ChartService.decodePortfolioHistory(portfolioHistoryJson)
        );
      }
      
      // Check if we already have a data point for today with the same value
      final today = DateTime(timestamp.year, timestamp.month, timestamp.day);
      bool hasMatchingDataPointForToday = false;
      
      for (final point in historyData) {
        final pointTime = DateTime.parse(point['timestamp']);
        final pointDate = DateTime(pointTime.year, pointTime.month, pointTime.day);
        final pointValue = (point['value'] as num).toDouble();
        
        // If we have a point for today with the same value (within small rounding error)
        if (pointDate.isAtSameMomentAs(today) && 
            (pointValue - totalValue).abs() < 0.01) {
          hasMatchingDataPointForToday = true;
          break;
        }
      }
      
      // Only add new data point if:
      // 1. We don't have one for today with the same value, OR
      // 2. This is a force update
      if (!hasMatchingDataPointForToday || forceCreate) {
        // Add new data point
        historyData.add({
          'timestamp': timestamp.toIso8601String(),
          'value': totalValue,
        });
        
        // Process and optimize data points (remove redundant points, etc.)
        historyData = _optimizeHistoryPoints(historyData);
        
        // Save updated history
        await _storageService!.prefs.setString(
          portfolioHistoryKey, 
          ChartService.encodePortfolioHistory(historyData)
        );
        
        LoggingService.debug('Added portfolio value point: $totalValue at ${timestamp.toIso8601String()}');
      }
      
      return true;
    } catch (e) {
      LoggingService.debug('Error creating portfolio snapshot: $e');
      return false;
    }
  }
  
  /// Optimize history points to prevent too many data points
  /// while maintaining an accurate representation of value over time
  List<Map<String, dynamic>> _optimizeHistoryPoints(List<Map<String, dynamic>> points) {
    // Sort by timestamp
    points.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp']);
      final bTime = DateTime.parse(b['timestamp']);
      return aTime.compareTo(bTime);
    });
    
    // If we have too many points, reduce them
    if (points.length > 365) { // Keep maximum of ~1 year of daily data
      // Remove older points with higher frequency
      final newPoints = <Map<String, dynamic>>[];
      
      // Keep more recent points (last 90 days) at full fidelity
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      // Process older points
      List<Map<String, dynamic>> olderPoints = [];
      List<Map<String, dynamic>> recentPoints = [];
      
      for (final point in points) {
        final timestamp = DateTime.parse(point['timestamp']);
        if (timestamp.isAfter(cutoffDate)) {
          recentPoints.add(point);
        } else {
          olderPoints.add(point);
        }
      }
      
      // Keep only weekly data points for older data
      if (olderPoints.isNotEmpty) {
        Map<String, Map<String, dynamic>> weeklyPoints = {};
        
        for (final point in olderPoints) {
          final date = DateTime.parse(point['timestamp']);
          // Get ISO week number as key
          final weekKey = '${date.year}-W${(date.day / 7).ceil()}';
          
          // Only keep the latest point from each week
          if (!weeklyPoints.containsKey(weekKey) || 
              DateTime.parse(weeklyPoints[weekKey]!['timestamp']).isBefore(date)) {
            weeklyPoints[weekKey] = point;
          }
        }
        
        newPoints.addAll(weeklyPoints.values);
      }
      
      // Add all recent points
      newPoints.addAll(recentPoints);
      
      // Make sure the points are sorted
      newPoints.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp']);
        final bTime = DateTime.parse(b['timestamp']);
        return aTime.compareTo(bTime);
      });
      
      return newPoints;
    }
    
    return points;
  }
  
  /// Force an immediate snapshot update
  Future<bool> forceUpdate() async {
    if (!_isInitialized || _storageService == null) {
      return false;
    }
    
    try {
      // Get current cards
      final cards = await _storageService!.watchCards().first;
      
      // ALWAYS create a snapshot even if we have no cards, using 0.0 value
      final now = DateTime.now();
      final snapshotTaken = await _takePortfolioSnapshot(cards, now, forceCreate: true);
      
      if (snapshotTaken) {
        // Update last snapshot time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSnapshotKey, now.toIso8601String());
        LoggingService.debug('Forced portfolio snapshot created at ${now.toString()}');
      }
      
      return snapshotTaken;
    } catch (e) {
      LoggingService.debug('Error forcing portfolio snapshot update: $e');
      return false;
    }
  }
  
  /// Clean up resources used by the service
  void dispose() {
    _scheduledUpdateTimer?.cancel();
    _isInitialized = false;
    _storageService = null;
  }
}
