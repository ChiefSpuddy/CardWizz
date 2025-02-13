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
      // Parse and convert all values to current currency using base EUR rate
      final List<dynamic> history = json.decode(portfolioHistoryJson);
      final points = history.map((point) {
        final timestamp = DateTime.parse(point['timestamp']);
        // Values are stored in EUR, convert to target currency using current rate
        final eurValue = (point['value'] as num).toDouble();
        final convertedValue = eurValue * currencyProvider.rate;
        return (timestamp, convertedValue);
      }).toList();

      if (points.length < 2) {
        return _buildEmptyState(context);
      }

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
      final yPadding = yRange * 0.15;

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 8, 16),
          child: SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: Colors.green.shade600,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.shade600.withOpacity(0.15),
                          Colors.green.shade600.withOpacity(0.0),
                        ],
                        stops: const [0.2, 0.9],
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 2.5,
                        color: Colors.white,
                        strokeWidth: 1.5,
                        strokeColor: Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
                minY: (minY - yPadding).clamp(0, double.infinity),
                maxY: maxY + yPadding,
                borderData: FlBorderData(show: false),
                clipData: FlClipData.all(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Theme.of(context).colorScheme.surface,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                        return LineTooltipItem(
                          '${_formatDate(date)}\n${currencyProvider.formatValue(spot.y)}',
                          const TextStyle(
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  touchSpotThreshold: 30, // Increased for better touch detection
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (_, indicators) {
                    return indicators.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: Colors.green.shade200,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 4, // Smaller radius for touched spot
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.green.shade600,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yRange / 5, // Adjusted for better spacing
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: const Duration(days: 5).inMilliseconds.toDouble(),
                      getTitlesWidget: (value, _) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 10, // Smaller font
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
                      reservedSize: 40, // Reduced width
                      getTitlesWidget: (value, _) {
                        // Only show label if it's not at the very top or bottom of the range
                        if (value == minY || value == maxY) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4), // Reduced padding
                          child: Text(
                            _formatValue(value, currencyProvider),
                            style: TextStyle(
                              fontSize: 10, // Smaller font
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                      interval: yRange / 3, // Show fewer labels
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: maxY,
                      color: Colors.green.shade300.withOpacity(0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 8, bottom: 4),
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                        labelResolver: (_) => currencyProvider.formatValue(maxY),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  fontSize: 11,
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
          reservedSize: 46,
          interval: null,
          getTitlesWidget: (value, _) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              currencyProvider.formatChartValue(double.parse(value.toStringAsFixed(2))),
              style: TextStyle(
                fontSize: 11,
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

  // Add this method to normalize spot spacing
  List<FlSpot> _normalizeSpots(List<FlSpot> spots) {
    if (spots.isEmpty) return [];
    
    // Find time range
    final startTime = spots.first.x;
    final endTime = spots.last.x;
    final timeRange = endTime - startTime;
    
    // Normalize spots to have equal spacing
    return spots.map((spot) {
      final normalizedX = (spot.x - startTime) / timeRange * 100;
      return FlSpot(normalizedX, spot.y);
    }).toList();
  }

  // Update method signature to accept BuildContext
  double _calculateDateInterval(List<FlSpot> spots, BuildContext context) {
    if (spots.length <= 1) return 1;
    
    final totalWidth = MediaQuery.of(context).size.width;
    final desiredLabelCount = (totalWidth / 100).floor(); // One label per 100px
    
    final startTime = spots.first.x;
    final endTime = spots.last.x;
    final timeRange = endTime - startTime;
    
    return timeRange / desiredLabelCount;
  }

  // New helper method for formatting values
  String _formatValue(double value, CurrencyProvider currencyProvider) {
    if (value >= 1000) {
      return '${currencyProvider.symbol}${(value / 1000).toStringAsFixed(1)}k';
    }
    return '${currencyProvider.symbol}${value.toInt()}';
  }
}
