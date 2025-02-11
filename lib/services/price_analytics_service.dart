import 'dart:math';
import '../models/tcg_card.dart';
import '../models/price_change.dart';

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
    final totalValue = calculateTotalValue(cards);
    
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

  static double calculateTotalValue(List<TcgCard> cards) {
    return cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
  }

  static List<PriceChange> getTopMovers(List<TcgCard> cards, {Duration period = const Duration(hours: 24)}) {
    return cards
        .where((card) => card.priceHistory.length > 1)
        .map((card) {
          final change = card.getPriceChange(period) ?? 0;
          final currentPrice = card.price ?? 0;
          final previousPrice = card.getPriceAtDate(DateTime.now().subtract(period)) ?? currentPrice;
          
          return PriceChange(
            card: card,
            currentPrice: currentPrice,
            previousPrice: previousPrice,
            percentageChange: change,
          );
        })
        .where((priceChange) => priceChange.percentageChange.abs() > 0.1)  // Filter out tiny changes
        .toList()
      ..sort((a, b) => b.percentageChange.abs().compareTo(a.percentageChange.abs()));
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
        // Find the closest price point before or at this date
        final pricePoint = card.priceHistory
            .where((p) => !p.timestamp.isAfter(date))
            .lastOrNull;
            
        // Use historical price if available, otherwise current price
        totalValue += pricePoint?.price ?? card.price ?? 0;
      }
      
      if (totalValue > 0) {  // Only add points with value
        dailyValues[date] = totalValue;
      }
    }

    // Always include current total value
    dailyValues[now] = calculateTotalValue(cards);

    return dailyValues.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }
}
