import 'tcg_card.dart';

class PriceChange {
  final TcgCard card;
  final double currentPrice;
  final double previousPrice;
  final double percentageChange;

  PriceChange({
    required this.card,
    required this.currentPrice,
    required this.previousPrice,
    required this.percentageChange,
  });
}
