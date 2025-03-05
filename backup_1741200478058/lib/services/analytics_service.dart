import '../models/tcg_card.dart';
import 'dart:math';

class AnalyticsService {
  static const List<Duration> _periods = [
    Duration(days: 1),
    Duration(days: 7),
    Duration(days: 30),
    Duration(days: 90),
  ];

  static Map<String, double> calculatePriceChanges(TcgCard card) {
    final changes = <String, double>{};
    
    final periods = [
      ('24h', const Duration(days: 1)),
      ('7d', const Duration(days: 7)),
      ('30d', const Duration(days: 30)),
    ];

    for (final (label, duration) in periods) {
      final change = card.getPriceChange(duration);
      if (change != null) {
        changes[label] = change;
      }
    }

    return changes;
  }

  static Map<String, dynamic> getCardPriceStats(TcgCard card) {
    if (card.priceHistory.isEmpty) return {};

    final prices = card.priceHistory.map((pp) => pp.price).toList();
    prices.sort();

    final avg = prices.reduce((a, b) => a + b) / prices.length;
    final min = prices.first;
    final max = prices.last;

    // Calculate volatility (standard deviation)
    final sumSquares = prices.map((p) => pow(p - avg, 2)).reduce((a, b) => a + b);
    final volatility = sqrt(sumSquares / prices.length);

    return {
      'average': avg,
      'minimum': min,
      'maximum': max,
      'volatility': volatility,
      'pricePoints': card.priceHistory,
    };
  }

  static List<MapEntry<DateTime, double>> getPriceTimeline(
    List<TcgCard> cards, {
    Duration period = const Duration(days: 30),
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(period);
    
    // Group all price points by date
    final dailyPrices = <DateTime, List<double>>{};
    
    for (final card in cards) {
      for (final pp in card.priceHistory) {
        if (pp.timestamp.isAfter(startDate)) {
          final date = DateTime(
            pp.timestamp.year,
            pp.timestamp.month,
            pp.timestamp.day,
          );
          dailyPrices.putIfAbsent(date, () => []).add(pp.price);
        }
      }
    }

    // Calculate daily averages
    return dailyPrices.entries
        .map((e) => MapEntry(
          e.key,
          e.value.reduce((a, b) => a + b) / e.value.length,
        ))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }
}
