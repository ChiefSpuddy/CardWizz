import 'dart:math' show min, max;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../providers/currency_provider.dart';

class PortfolioValueChart extends StatelessWidget {
  const PortfolioValueChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final storageService = Provider.of<StorageService>(context, listen: false);
    final cards = Provider.of<List<TcgCard>>(context);

    // Get portfolio history
    final portfolioHistoryKey = storageService.getUserKey('portfolio_history');
    final portfolioHistoryJson = storageService.prefs.getString(portfolioHistoryKey);

    if (portfolioHistoryJson == null) {
      return _buildEmptyState(context);
    }

    try {
      // Parse history points
      final List<dynamic> history = json.decode(portfolioHistoryJson);
      final points = history.map((point) {
        final timestamp = DateTime.parse(point['timestamp']);
        final value = (point['value'] as num).toDouble();
        return (timestamp, value);
      }).toList();

      if (points.length < 2) {
        return _buildEmptyState(context);
      }

      // Convert to chart spots
      final spots = points.map((point) {
        return FlSpot(
          point.$1.millisecondsSinceEpoch.toDouble(),
          point.$2,
        );
      }).toList();

      // Calculate value range
      final values = points.map((p) => p.$2).toList();
      final maxY = values.reduce(max);
      final minY = values.reduce(min);
      final yRange = maxY - minY;
      final yPadding = yRange * 0.1; // 10% padding

      return SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: (minY - yPadding).clamp(0, double.infinity),
            maxY: maxY + yPadding,
            clipData: FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: yRange / 5,
            ),
            titlesData: _buildTitles(context, currencyProvider),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                preventCurveOverShooting: true,
                color: Colors.green.shade600,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.green.shade600.withOpacity(0.3),
                      Colors.green.shade600.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building chart: $e');
      return _buildEmptyState(context);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Price Trend Coming Soon',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back tomorrow to see how your collection value changes over time!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  FlTitlesData _buildTitles(BuildContext context, CurrencyProvider currencyProvider) {
    return FlTitlesData(
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: const Duration(days: 7).inMilliseconds.toDouble(),
          getTitlesWidget: (value, _) {
            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: null, // Let FL Chart determine the interval
          reservedSize: 46,
          getTitlesWidget: (value, _) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              currencyProvider.formatValue(value),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}
