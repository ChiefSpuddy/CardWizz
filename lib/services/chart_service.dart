import '../services/logging_service.dart';
import 'dart:convert';
import 'storage_service.dart';
// Add import for TcgCard
import '../models/tcg_card.dart';
// Use the local TcgSet import
import '../models/tcg_set.dart' as models;

class ChartService {
  // Add minimum time between points
  static const Duration _minimumTimeBetweenPoints = Duration(minutes: 30);

  static List<(DateTime, double)> getPortfolioHistory(StorageService storage, List<TcgCard> cards) {
    final portfolioHistoryKey = storage.getUserKey('portfolio_history');
    final portfolioHistoryJson = storage.prefs.getString(portfolioHistoryKey);
    
    if (portfolioHistoryJson == null) {
      // Store initial point with current EUR value
      final now = DateTime.now();
      final currentValue = calculateTotalValue(cards); // Values are already in EUR
      return [(now, currentValue)];
    }

    try {
      final List<dynamic> history = json.decode(portfolioHistoryJson);
      var points = history.map<(DateTime, double)>((point) {
        return (
          DateTime.parse(point['timestamp'] as String),
          (point['value'] as num).toDouble(), // Keep as EUR value
        );
      }).toList();
      
      // Sort by date
      points.sort((a, b) => a.$1.compareTo(b.$1));
      
      // Remove points older than 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      points = points.where((p) => p.$1.isAfter(thirtyDaysAgo)).toList();
      
      // Add current value if different (in EUR)
      final currentValue = calculateTotalValue(cards);
      final now = DateTime.now();
      
      if (points.isEmpty || points.last.$2 != currentValue) {
        points.add((now, currentValue));
      }
      
      return points;
    } catch (e) {
      LoggingService.debug('Error parsing portfolio history: $e');
      return [(DateTime.now(), calculateTotalValue(cards))];
    }
  }

  // Fix the implementation of getPortfolioHistoryRaw to avoid using PriceService and getPortfolioSnapshots
  static List<(DateTime, double)> getPortfolioHistoryRaw(StorageService storageService, List<TcgCard> cards) {
    // Instead of using PriceService, we'll use the existing getPortfolioHistory method
    // and just make sure we're returning raw prices
    final points = getPortfolioHistory(storageService, cards);
    
    // The portfolio history already uses raw prices from the cards,
    // so we can return the same data
    
    // Make sure the last point has the current total value
    if (points.isNotEmpty) {
      final now = DateTime.now();
      final currentTotal = calculateTotalValue(cards);
      
      // Update the last point if it's from today, otherwise add a new point
      final lastPoint = points.last;
      if (_isSameDay(lastPoint.$1, now)) {
        // Replace the last point with current value
        points[points.length - 1] = (now, currentTotal);
      } else {
        // Add a new point for today
        points.add((now, currentTotal));
      }
    }
    
    return points;
  }

  // Helper to check if two dates are on the same day
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // New method to combine points that are too close together
  static List<(DateTime, double)> _combineClosePoints(List<(DateTime, double)> points) {
    if (points.length < 2) return points;

    final result = <(DateTime, double)>[];
    var currentPoint = points.first;
    var runningSum = currentPoint.$2;
    var count = 1;

    for (var i = 1; i < points.length; i++) {
      final nextPoint = points[i];
      final timeDiff = nextPoint.$1.difference(currentPoint.$1);

      if (timeDiff < _minimumTimeBetweenPoints) {
        // Combine points
        runningSum += nextPoint.$2;
        count++;
      } else {
        // Add averaged point and start new group
        result.add((currentPoint.$1, runningSum / count));
        currentPoint = nextPoint;
        runningSum = nextPoint.$2;
        count = 1;
      }
    }

    // Add last point
    if (count > 0) {
      result.add((currentPoint.$1, runningSum / count));
    }

    return result;
  }

  // New method to distribute points evenly
  static List<(DateTime, double)> _distributePoints(List<(DateTime, double)> points, int targetCount) {
    if (points.length <= targetCount) return points;

    final result = <(DateTime, double)>[];
    final timeRange = points.last.$1.difference(points.first.$1);
    final interval = timeRange.inMinutes ~/ targetCount;

    var currentTime = points.first.$1;
    var currentIndex = 0;

    // Always include first point
    result.add(points.first);

    // Distribute middle points
    while (currentTime.isBefore(points.last.$1)) {
      currentTime = currentTime.add(Duration(minutes: interval));
      
      // Find closest point
      while (currentIndex < points.length && 
             points[currentIndex].$1.isBefore(currentTime)) {
        currentIndex++;
      }

      if (currentIndex < points.length) {
        result.add(points[currentIndex]);
      }
    }

    // Always include last point
    if (result.last != points.last) {
      result.add(points.last);
    }

    return result;
  }

  static double calculateTotalValue(List<TcgCard> cards) {
    return cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
  }
}

// Mock implementation of portfolio snapshot for backwards compatibility
// This avoids having to change the StorageService
class PortfolioSnapshot {
  final DateTime date;
  final List<TcgCard> cards;
  
  PortfolioSnapshot({required this.date, required this.cards});
}

// Extension method to add getPortfolioSnapshots to StorageService
extension PortfolioExtension on StorageService {
  List<PortfolioSnapshot> getPortfolioSnapshots() {
    // Create a snapshot for the current date based on portfolio_history
    final portfolioHistoryKey = getUserKey('portfolio_history');
    final portfolioHistoryJson = prefs.getString(portfolioHistoryKey);
    
    if (portfolioHistoryJson == null) {
      // No history yet
      return [];
    }
    
    try {
      final List<dynamic> history = json.decode(portfolioHistoryJson);
      final snapshots = history.map<PortfolioSnapshot>((point) {
        final date = DateTime.parse(point['timestamp'] as String);
        final value = (point['value'] as num).toDouble();
        
        // Create a mock card to represent the value at this date
        final mockCard = TcgCard(
          id: 'snapshot_${date.millisecondsSinceEpoch}',
          name: 'Portfolio Snapshot',
          imageUrl: '',
          price: value,
          set: models.TcgSet(id: '', name: ''),  // Use aliased version
        );
        
        return PortfolioSnapshot(
          date: date,
          cards: [mockCard],
        );
      }).toList();
      
      return snapshots;
    } catch (e) {
      LoggingService.debug('Error parsing portfolio history: $e');
      return [];
    }
  }
}
