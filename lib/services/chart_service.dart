import 'dart:convert';
import '../models/tcg_card.dart';
import 'storage_service.dart';

class ChartService {
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

      // Convert to points and ensure valid dates and values
      var points = history.map((point) {
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
      .toList();

      // Filter invalid dates and sort
      points = points
          .where((point) => 
              point.$1.isAfter(thirtyDaysAgo) && 
              !point.$1.isAfter(now) &&
              point.$2 >= 0)
          .toList()
        ..sort((a, b) => a.$1.compareTo(b.$1));

      if (points.isEmpty) {
        points = [(thirtyDaysAgo, 0.0), (now, calculateTotalValue(cards))];
      } else {
        // Ensure we have a starting point
        if (points.first.$1.isAfter(thirtyDaysAgo)) {
          points.insert(0, (thirtyDaysAgo, 0.0));
        }

        // Ensure we have the latest value
        final currentValue = calculateTotalValue(cards);
        if (points.last.$2 != currentValue) {
          points.add((now, currentValue));
        }
      }

      print('Portfolio history points:');
      for (final point in points) {
        print('${point.$1}: \$${point.$2.toStringAsFixed(2)}');
      }

      return points;
    } catch (e) {
      print('Error getting portfolio history: $e');
      return [];
    }
  }

  static double calculateTotalValue(List<TcgCard> cards) {
    return cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
  }
}
