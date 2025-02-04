import 'dart:math';
import '../models/tcg_card.dart';

class CollectionValueService {
  static final CollectionValueService _instance = CollectionValueService._internal();
  
  factory CollectionValueService() {
    return _instance;
  }

  CollectionValueService._internal();

  List<MapEntry<DateTime, double>> getValueHistory(List<TcgCard> cards) {
    final timelinePoints = <DateTime, double>{};
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    // First, get all dates in the range
    final dates = List.generate(31, (index) => 
      thirtyDaysAgo.add(Duration(days: index))
    );

    // For each date, calculate the total value based on cards owned at that time
    for (final date in dates) {
      double totalValue = 0;
      
      for (final card in cards) {
        // Safely handle null addedToCollection dates
        final addedDate = card.addedToCollection ?? now;
        
        // Check if card was in collection at this date
        if (addedDate.isBefore(date) || addedDate.isAtSameMomentAs(date)) {
          // Find the closest price point before this date
          final pricePoint = card.priceHistory
              .where((p) => p.date.isBefore(date) || p.date.isAtSameMomentAs(date))
              .lastOrNull;
          
          if (pricePoint != null) {
            totalValue += pricePoint.price;
          } else {
            totalValue += card.price ?? 0; // Fallback to current price
          }
        }
      }
      
      // Only add points where we have value
      if (totalValue > 0) {
        timelinePoints[date] = totalValue;
      }
    }

    return timelinePoints.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  Map<String, double> getValueChanges(List<TcgCard> cards) {
    final changes = <String, double>{};
    final history = getValueHistory(cards);
    if (history.isEmpty) return changes;

    final now = DateTime.now();
    final currentValue = history.last.value;

    final periods = [
      ('24h', const Duration(days: 1)),
      ('7d', const Duration(days: 7)),
      ('30d', const Duration(days: 30)),
    ];

    for (final (label, duration) in periods) {
      final pastDate = now.subtract(duration);
      final pastValue = history
          .where((entry) => entry.key.isBefore(pastDate))
          .lastOrNull
          ?.value ?? history.first.value;
      
      if (pastValue > 0) {
        final change = ((currentValue - pastValue) / pastValue) * 100;
        changes[label] = change;
      }
    }

    return changes;
  }

  double getProjectedValue(List<TcgCard> cards) {
    final history = getValueHistory(cards);
    if (history.length < 2) return 0;

    // Simple linear regression
    final x = List.generate(history.length, (i) => i.toDouble());
    final y = history.map((e) => e.value).toList();
    
    final n = history.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((xi) => xi * xi).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    // Project value 7 days into the future
    return slope * (n + 7) + intercept;
  }

  double getVolatility(List<TcgCard> cards) {
    final history = getValueHistory(cards);
    if (history.length < 2) return 0;

    final values = history.map((e) => e.value).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    final sumSquares = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b);
    return sqrt(sumSquares / (values.length - 1)) / mean * 100;
  }
}
