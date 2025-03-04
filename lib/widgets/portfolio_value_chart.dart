import 'dart:async';
import 'dart:math' show min, max, pow, log;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../providers/currency_provider.dart';

class PortfolioValueChart extends StatefulWidget {
  final bool useFullWidth;
  final double chartPadding;

  const PortfolioValueChart({
    Key? key, 
    this.useFullWidth = false,
    this.chartPadding = 0, // Default to 0 for backward compatibility
  }) : super(key: key);

  @override
  State<PortfolioValueChart> createState() => _PortfolioValueChartState();
}

class _PortfolioValueChartState extends State<PortfolioValueChart> {
  late final StorageService _storage;
  late final StreamSubscription _cardsChangedSubscription;

  @override
  void initState() {
    super.initState();
    _storage = Provider.of<StorageService>(context, listen: false);
    
    // Listen for card changes to refresh chart
    _cardsChangedSubscription = _storage.onCardsChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cardsChangedSubscription.cancel();
    super.dispose();
  }

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
      // Parse points but DON'T convert to target currency here
      final List<dynamic> history = json.decode(portfolioHistoryJson);
      final points = history.map((point) {
        final timestamp = DateTime.parse(point['timestamp']);
        final eurValue = (point['value'] as num).toDouble();
        // Keep as EUR value
        return (timestamp, eurValue);
      }).toList()
        ..sort((a, b) => a.$1.compareTo(b.$1));

      if (points.length < 2) {
        return _buildEmptyState(context);
      }

      // Sample points to reduce density (take every nth point)
      final sampledPoints = points.asMap().entries
          .where((entry) => 
              entry.key % max(1, (points.length / 20).round()) == 0 || // Take every nth point
              entry.key == 0 || // Always include first point
              entry.key == points.length - 1) // Always include last point
          .map((e) => e.value)
          .toList();

      // Create normalized spots with equal spacing
      final spots = List<FlSpot>.generate(sampledPoints.length, (index) {
        final normalizedX = index * (100 / (sampledPoints.length - 1));
        return FlSpot(normalizedX, sampledPoints[index].$2);
      });

      // Calculate value range using all points for accurate min/max
      final values = points.map((p) => p.$2).toList();
      final maxY = values.reduce(max);
      final minY = values.reduce(min);
      final yRange = maxY - minY;
      final yPadding = yRange * 0.15;

      // Calculate time range and adapt interval
      final timeRange = points.last.$1.difference(points.first.$1);
      final daysSpan = timeRange.inDays;
      
      // Adjust interval based on time range
      final interval = daysSpan <= 7 
          ? const Duration(days: 1).inMilliseconds.toDouble()
          : daysSpan <= 14 
              ? const Duration(days: 2).inMilliseconds.toDouble()
              : const Duration(days: 5).inMilliseconds.toDouble();

      // Adjust the minY and maxY values to account for padding
      final adjustedMinY = widget.chartPadding > 0
          ? (minY - yPadding - widget.chartPadding).clamp(0, double.infinity).toDouble() // Convert to double
          : (minY - yPadding).clamp(0, double.infinity).toDouble(); // Convert to double
          
      final adjustedMaxY = widget.chartPadding > 0
          ? (maxY + yPadding + widget.chartPadding).toDouble() // Convert to double 
          : (maxY + yPadding).toDouble(); // Convert to double

      // Return the chart directly without the Card wrapper
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          height: 250,
          child: Padding(
            padding: widget.useFullWidth 
                ? EdgeInsets.only(bottom: widget.chartPadding)
                : const EdgeInsets.symmetric(horizontal: 24),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.useFullWidth 
                        ? spots  // Use original spots with no adjustment
                        : _adjustSpotsForPadding(spots),
                    isCurved: true,
                    curveSmoothness: 0.6, // Increased for smoother curve
                    preventCurveOverShooting: true,
                    color: Colors.green.shade600,
                    barWidth: 3, // Slightly thicker line
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.green.shade600.withOpacity(0.4), // More visible gradient
                          Colors.green.shade600.withOpacity(0.0),
                        ],
                        stops: const [0.2, 1.0], // Adjusted gradient stops
                      ),
                    ),
                  ),
                ],
                minY: adjustedMinY, // Now this is a proper double
                maxY: adjustedMaxY, // Now this is a proper double
                borderData: FlBorderData(show: false),
                clipData: FlClipData.all(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Theme.of(context).colorScheme.surface,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipMargin: 8,
                    fitInsideHorizontally: true, // Add this to prevent horizontal overflow
                    fitInsideVertically: true, // Optional: Also prevent vertical overflow
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        // Convert normalized x value back to actual timestamp
                        final index = (spot.x * (points.length - 1) / 100).round();
                        if (index >= 0 && index < points.length) {
                          final date = points[index].$1;  // Get actual date from points
                          return LineTooltipItem(
                            '${_formatDate(date)}\n${currencyProvider.formatValue(spot.y)}',
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                          );
                        }
                        return null;
                      }).whereType<LineTooltipItem>().toList();
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
                        FlDotData(show: false), // Don't show dots when touched
                      );
                    }).toList();
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false, // Remove vertical lines
                  horizontalInterval: yRange / 4, // Adjusted for fewer lines
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                  // Remove vertical grid lines near edges
                  checkToShowVerticalLine: (value) =>
                      value > 5 && value < 95, // Only show grid lines between 5% and 95%
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Removed left titles
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20, // Show 4 evenly spaced dates
                      reservedSize: 24, // Increased from default
                      getTitlesWidget: (value, _) {
                        // Only show labels between 10 and 90 to prevent edge overlap
                        if (value < 10 || value > 90) return const SizedBox.shrink();
                        
                        final index = (value * (points.length - 1) / 100).round();
                        if (index >= 0 && index < points.length) {
                          final date = points[index].$1;
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
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: maxY,
                      color: Colors.green.shade300.withOpacity(0.2),
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
    // Fix date formatting to ensure two digits for both day and month
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

  double _calculateNiceInterval(double range) {
    // Aim for 4-6 labels on the Y axis
    const targetLabelCount = 5;
    
    // Calculate a rough interval
    double interval = range / targetLabelCount;
    
    // Round to a nice number - use log10
    final magnitude = (log(interval.abs()) / log(10)).floor();
    final power = pow(10, magnitude);
    
    // Try standard intervals
    final candidates = [1.0, 2.0, 2.5, 5.0, 10.0];
    final normalizedInterval = interval / power;
    
    // Find the closest nice number
    double niceInterval = candidates.first * power;
    double minDiff = (normalizedInterval - candidates.first).abs();
    
    for (final candidate in candidates.skip(1)) {
      final diff = (normalizedInterval - candidate).abs();
      if (diff < minDiff) {
        minDiff = diff;
        niceInterval = candidate * power;
      }
    }
    
    return niceInterval;
  }

  // Add this helper method to detect significant price changes
  bool _isSignificantChange(List<FlSpot> spots, int index) {
    if (index <= 0 || index >= spots.length - 1) return false;
    
    final previous = spots[index - 1].y;
    final current = spots[index].y;
    final next = spots[index + 1].y;
    
    // Calculate percentage changes
    final changeFromPrev = (current - previous).abs() / previous;
    final changeToNext = (next - current).abs() / current;
    
    // Increased threshold to only show more significant changes
    return changeFromPrev > 0.08 || changeToNext > 0.08;
  }

  // Add this new helper method
  List<FlSpot> _adjustSpotsForPadding(List<FlSpot> spots) {
    const paddingPercentage = 8.0; // Increased padding percentage
    return spots.map((spot) {
      // Scale to ~85% of width with more padding on sides
      final adjustedX = (spot.x * ((100 - (paddingPercentage * 2)) / 100)) + paddingPercentage;
      return FlSpot(adjustedX, spot.y);
    }).toList();
  }

  // Add this method to create box decoration
  BoxDecoration _createChartDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).cardColor,
          Theme.of(context).cardColor.withOpacity(0.95),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// Also make the FullWidthPortfolioChart transparent
class FullWidthPortfolioChart extends StatelessWidget {
  const FullWidthPortfolioChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PortfolioValueChart(
              useFullWidth: true, 
              chartPadding: 16,
            ),
          ),
        );
      },
    );
  }
}
