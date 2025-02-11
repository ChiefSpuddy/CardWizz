import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/price_analytics_service.dart';
import '../providers/currency_provider.dart';
import '../models/tcg_card.dart';

class ValueTrendChart extends StatelessWidget {
  final List<TcgCard> cards;
  final void Function(double value, DateTime date)? onPointSelected;

  const ValueTrendChart({
    super.key,
    required this.cards,
    this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Move _buildValueTrendCard content here
    // ...existing chart building code...
  }
}
