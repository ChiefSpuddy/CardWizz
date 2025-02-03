import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tcg_card.dart';
import '../services/price_analytics_service.dart';

class PriceTrendChart extends StatelessWidget {
  final List<TcgCard> cards;
  final Duration period;
  
  const PriceTrendChart({
    super.key,
    required this.cards,
    this.period = const Duration(days: 30),
  });

  @override
  Widget build(BuildContext context) {
    final timeline = PriceAnalyticsService.getValueTimeline(cards, period: period);
    if (timeline.isEmpty) return const SizedBox.shrink();

    final spots = timeline.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          // ...chart configuration using spots...
        ),
      ),
    );
  }
}
