import 'dart:math';
import '../models/tcg_card.dart';

class PriceAnalyticsService {
  static const List<Duration> standardPeriods = [
    Duration(hours: 24),
    Duration(days: 7),
    Duration(days: 30),
    Duration(days: 90),
  ];

  static Map<String, double> getCollectionStats(List<TcgCard> cards) {
    if (cards.isEmpty) return {};

    final now = DateTime.now();
    final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
    
    // Calculate period changes
    final changes = <String, double>{};
    for (final period in standardPeriods) {
      final oldTotal = cards.fold<double>(0, (sum, card) {
        final oldPrice = card.priceHistory
            .where((p) => p.timestamp.isBefore(now.subtract(period)))
            .lastOrNull
            ?.price ?? card.price ?? 0;
        return sum + oldPrice;
      });
      
      if (oldTotal > 0) {
        final change = ((totalValue - oldTotal) / oldTotal) * 100;
        final key = period.inHours == 24 ? '24h' :
                   period.inDays == 7 ? '7d' :
                   period.inDays == 30 ? '30d' : '90d';
        changes[key] = change;
      }
    }

    return {
      'totalValue': totalValue,
      'avgValue': totalValue / cards.length,
      ...changes,
    };
  }

  static List<TcgCard> getTopMovers(List<TcgCard> cards, {Duration period = const Duration(hours: 24)}) {
    return cards
        .where((card) => card.priceHistory.length > 1)
        .map((card) => (card, card.getPriceChange(period) ?? 0))
        .where((tuple) => tuple.$2.abs() > 0.1)  // Filter out tiny changes
        .toList()
      ..sort((a, b) => b.$2.abs().compareTo(a.$2.abs()));
  }

  static List<MapEntry<DateTime, double>> getValueTimeline(
    List<TcgCard> cards, {
    Duration period = const Duration(days: 30),
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(period);
    
    // Group price points by date
    final dailyValues = <DateTime, double>{};
    
    for (var i = 0; i <= period.inDays; i++) {
      final date = startDate.add(Duration(days: i));
      double totalValue = 0;
      
      for (final card in cards) {
        final price = card.priceHistory
            .where((p) => !p.timestamp.isAfter(date))
            .lastOrNull
            ?.price ?? card.price ?? 0;
        totalValue += price;
      }
      
      dailyValues[date] = totalValue;
    }

    return dailyValues.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }
}
