import 'package:cardwizz/models/tcg_card.dart';

// Add PricePoint class
class PricePoint {
  final DateTime date;
  final double price;
  final String source;

  DateTime get timestamp => date;

  const PricePoint({
    required this.date,
    required this.price,
    required this.source,
  });
}

// Add TrendData class
class TrendData {
  final double changePercent;
  final double volume;
  final double priceAverage;
  final double volatility;

  const TrendData({
    required this.changePercent,
    required this.volume,
    required this.priceAverage,
    required this.volatility,
  });
}

enum TrendDirection {
  up,
  down,
  neutral
}

class PriceTrend {
  final double changePercent;
  final TrendDirection direction;
  final double volatility;
  final double r2Score; // R-squared value for trend reliability

  const PriceTrend({
    required this.changePercent,
    required this.direction,
    required this.volatility,
    required this.r2Score,
  });
}

class TradeRecommendation {
  final TcgCard card;
  final String action; // "Buy", "Sell", "Hold"
  final String reason;
  final double confidence;

  const TradeRecommendation({
    required this.card,
    required this.action,
    required this.reason,
    required this.confidence,
  });
}

class PortfolioAnalytics {
  final double totalValue;
  final double dailyChange;
  final double weeklyChange;
  final double monthlyChange;
  final double volatility;
  final List<MapEntry<DateTime, double>> valueHistory;

  const PortfolioAnalytics({
    required this.totalValue,
    required this.dailyChange,
    required this.weeklyChange,
    required this.monthlyChange,
    required this.volatility,
    required this.valueHistory,
  });
}

// Add this conversion extension
extension PriceHistoryEntryX on PriceHistoryEntry {
  PricePoint toPricePoint() {
    return PricePoint(
      date: date,
      price: price,
      source: source,
    );
  }
}
