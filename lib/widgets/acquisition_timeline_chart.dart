import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tcg_card.dart';
import 'package:intl/intl.dart';

class AcquisitionTimelineChart extends StatefulWidget {
  final List<TcgCard> cards;
  
  const AcquisitionTimelineChart({
    Key? key,
    required this.cards,
  }) : super(key: key);

  @override
  State<AcquisitionTimelineChart> createState() => _AcquisitionTimelineChartState();
}

class _AcquisitionTimelineChartState extends State<AcquisitionTimelineChart> {
  @override
  Widget build(BuildContext context) {
    // Generate the cumulative acquisition data
    final acquisitionData = _generateAcquisitionData(widget.cards);
    if (acquisitionData.isEmpty) {
      return Center(
        child: Text(
          'No acquisition data available',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Find min and max for scales
    final firstDate = acquisitionData.first.x.toDouble();
    final lastDate = acquisitionData.last.x.toDouble();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateNiceInterval(widget.cards.length.toDouble()),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                // Convert the double back to DateTime for formatting
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    DateFormat('MMM y').format(date),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                );
              },
              interval: _calculateDateInterval(firstDate, lastDate),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _calculateNiceInterval(widget.cards.length.toDouble()),
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: firstDate,
        maxX: lastDate,
        minY: 0,
        maxY: widget.cards.length.toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: acquisitionData,
            isCurved: false, // Straight lines between points
            barWidth: 3,
            color: Theme.of(context).colorScheme.primary,
            dotData: FlDotData(
              show: acquisitionData.length < 50, // Only show dots if we have few data points
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
  
  // Generate cumulative acquisition data points from cards
  List<FlSpot> _generateAcquisitionData(List<TcgCard> cards) {
    if (cards.isEmpty) return [];
    
    // Group cards by date
    final dateMap = <DateTime, int>{};
    for (final card in cards) {
      // Use dateAdded or created field instead of createdAt
      final date = DateTime(
        card.dateAdded?.year ?? DateTime.now().year,
        card.dateAdded?.month ?? DateTime.now().month,
        card.dateAdded?.day ?? DateTime.now().day,
      );
      dateMap[date] = (dateMap[date] ?? 0) + 1;
    }
    
    // Sort dates
    final dates = dateMap.keys.toList()..sort();
    
    // Create cumulative data points
    int runningTotal = 0;
    return dates.map((date) {
      runningTotal += dateMap[date]!;
      return FlSpot(
        date.millisecondsSinceEpoch.toDouble(),
        runningTotal.toDouble(),
      );
    }).toList();
  }
  
  // Calculate nice interval for y-axis
  double _calculateNiceInterval(double range) {
    if (range <= 10) return 1;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    if (range <= 500) return 50;
    return 100;
  }
  
  // Calculate appropriate date interval for x-axis
  double _calculateDateInterval(double firstDate, double lastDate) {
    final firstDateTime = DateTime.fromMillisecondsSinceEpoch(firstDate.toInt());
    final lastDateTime = DateTime.fromMillisecondsSinceEpoch(lastDate.toInt());
    final diffDays = lastDateTime.difference(firstDateTime).inDays;
    
    // Calculate appropriate interval
    if (diffDays <= 30) {
      return const Duration(days: 7).inMilliseconds.toDouble(); // Weekly
    } else if (diffDays <= 90) {
      return const Duration(days: 14).inMilliseconds.toDouble(); // Biweekly
    } else if (diffDays <= 365) {
      return const Duration(days: 30).inMilliseconds.toDouble(); // Monthly
    } else if (diffDays <= 365 * 2) {
      return const Duration(days: 90).inMilliseconds.toDouble(); // Quarterly
    } else {
      return const Duration(days: 365).inMilliseconds.toDouble(); // Yearly
    }
  }
}
