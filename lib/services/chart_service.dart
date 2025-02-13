import 'dart:convert';
import '../models/tcg_card.dart';
import 'storage_service.dart';

class ChartService {
  // Add minimum time between points
  static const Duration _minimumTimeBetweenPoints = Duration(minutes: 30);

  static List<(DateTime, double)> getPortfolioHistory(StorageService storage, List<TcgCard> cards) {
    final portfolioHistoryKey = storage.getUserKey('portfolio_history');
    final portfolioHistoryJson = storage.prefs.getString(portfolioHistoryKey);

    if (portfolioHistoryJson == null) {
      return [];
    }

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      final history = (jsonDecode(portfolioHistoryJson) as List)
          .cast<Map<String, dynamic>>();

      // Convert and sort all points first
      var allPoints = history.map((point) {
        try {
          final timestamp = DateTime.parse(point['timestamp']);
          final value = (point['value'] as num).toDouble();
          return (timestamp, value);
        } catch (e) {
          print('Error parsing point: $e');
          return null;
        }
      })
      .where((point) => point != null)
      .cast<(DateTime, double)>()
      .toList()
        ..sort((a, b) => a.$1.compareTo(b.$1));

      // Combine points that are too close together
      var points = _combineClosePoints(allPoints);

      // Filter date range
      points = points
          .where((point) => 
              point.$1.isAfter(thirtyDaysAgo) && 
              !point.$1.isAfter(now) &&
              point.$2 >= 0)
          .toList();

      // Handle empty or single point cases
      if (points.isEmpty) {
        points = [(thirtyDaysAgo, 0.0), (now, calculateTotalValue(cards))];
      } else if (points.length == 1) {
        points.insert(0, (thirtyDaysAgo, points[0].$2));
      }

      // Ensure even distribution of points
      points = _distributePoints(points, 20); // Aim for ~20 points on chart

      // Always include latest value
      final currentValue = calculateTotalValue(cards);
      if (points.isEmpty || points.last.$1.isBefore(now.subtract(const Duration(minutes: 5)))) {
        points.add((now, currentValue));
      }

      return points;
    } catch (e) {
      print('Error getting portfolio history: $e');
      return [];
    }
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
