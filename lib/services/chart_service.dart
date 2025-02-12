import '../models/tcg_card.dart';
import 'dart:math' show min, max, Random;  // Add Random here
import 'package:collection/collection.dart';  // Add this for firstWhereOrNull

class ChartService {
  static List<(DateTime, double)> getPortfolioHistory(List<TcgCard> cards) {
    if (cards.isEmpty) return [];
    
    final points = <(DateTime, double)>[];
    var runningTotal = 0.0;

    // Get all time points (card additions and price changes)
    final timePoints = <(DateTime, TcgCard, double)>[];

    // Add initial point
    points.add((
      DateTime.now().subtract(const Duration(days: 30)),
      0.0
    ));

    // Record when each card was added with its initial price
    for (final card in cards) {
      if (card.dateAdded != null) {
        timePoints.add((
          card.dateAdded!,
          card,
          card.price ?? 0
        ));

        // Also add price history points for this card
        for (final pricePoint in card.priceHistory) {
          timePoints.add((
            pricePoint.date,
            card,
            pricePoint.price
          ));
        }
      }
    }

    // Sort all points chronologically
    timePoints.sort((a, b) => a.$1.compareTo(b.$1));

    // Add points for each time point
    final cardPrices = <String, double>{};
    for (final point in timePoints) {
      final (date, card, price) = point;
      cardPrices[card.id] = price;
      
      // Calculate total at this point
      final total = cardPrices.values.fold<double>(0, (sum, p) => sum + p);
      points.add((date, total));
    }

    // Add current point
    final currentTotal = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
    points.add((DateTime.now(), currentTotal));

    return points;
  }

  static double calculateTotalAtDate(List<TcgCard> cards, DateTime date) {
    return cards
        .where((c) => c.dateAdded?.isBefore(date) ?? false)
        .fold<double>(0, (sum, card) => sum + (card.getPriceAtDate(date) ?? card.price ?? 0));
  }

  static double calculateTotalValue(List<TcgCard> cards) {
    return cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
  }

  static (double min, double max) getValueRange(List<(DateTime, double)> points) {
    if (points.isEmpty) return (0, 0);
    final values = points.map((p) => p.$2).toList();
    return (values.reduce(min), values.reduce(max));
  }

  static double calculatePercentageChange(List<(DateTime, double)> points) {
    if (points.length < 2) return 0;
    final firstValue = points.first.$2;
    final lastValue = points.last.$2;
    if (firstValue == 0) return 0;
    return ((lastValue - firstValue) / firstValue) * 100;
  }
}
