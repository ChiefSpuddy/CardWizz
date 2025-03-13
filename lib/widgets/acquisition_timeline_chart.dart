import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';

class AcquisitionTimelineChart extends StatelessWidget {
  final List<TcgCard> cards;
  final bool useFullWidth;
  final double chartPadding;

  const AcquisitionTimelineChart({
    Key? key,
    required this.cards,
    this.useFullWidth = false,
    this.chartPadding = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final timelineData = _calculateAcquisitionData();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (timelineData.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Get max and min values for scale
    int maxValue = timelineData.fold(0, (prev, point) => point.y > prev ? point.y : prev);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(chartPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card Acquisitions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ${cards.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'When you added cards to your collection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue + 1, // Add some padding at top
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxValue > 10 ? 5 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (_) => const FlLine(color: Colors.transparent),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value < 0 || value >= timelineData.length) {
                            return const SizedBox.shrink();
                          }
                          
                          // Format date for display
                          final date = timelineData[value.toInt()].date;
                          String title = DateFormat('MMM').format(date);
                          if (value == 0 || date.month == 1) {
                            title += '\n${date.year}';
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              title,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value == 0) return const SizedBox.shrink();
                          
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                        interval: maxValue > 10 ? 5 : 1,
                        reservedSize: 32,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: timelineData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.y.toDouble(),
                          color: _getMonthColor(data.date.month, colorScheme),
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxValue + 1,
                            color: colorScheme.surfaceVariant.withOpacity(0.1),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineInsights(context, timelineData),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimelineInsights(BuildContext context, List<_AcquisitionPoint> data) {
    // Find most active month
    var mostActivePoint = data.reduce((curr, next) => curr.y > next.y ? curr : next);
    
    // Calculate trend (% increase last 3 months vs prior)
    int recentCount = 0;
    int priorCount = 0;
    
    if (data.length >= 3) {
      final recent = data.sublist(data.length - 3);
      final prior = data.length > 6 ? data.sublist(data.length - 6, data.length - 3) : [];
      
      // Fix the fold operations by explicitly handling the ints
      recentCount = recent.fold<int>(0, (prev, point) => prev + (point.y as int));
      priorCount = prior.fold<int>(0, (prev, point) => prev + (point.y as int));
    }
    
    // Rest of the method remains unchanged
    final hasIncrease = priorCount > 0 && recentCount > priorCount;
    final hasDecrease = priorCount > 0 && recentCount < priorCount;
    final percentChange = priorCount > 0 ? ((recentCount - priorCount) / priorCount * 100).abs() : 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Collection Insights',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Most active: ${DateFormat('MMMM yyyy').format(mostActivePoint.date)} (${mostActivePoint.y} cards)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (priorCount > 0) ...[
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Recent trend: '),
                  TextSpan(
                    text: hasIncrease 
                      ? '↑ ${percentChange.toStringAsFixed(0)}% increase' 
                      : hasDecrease 
                        ? '↓ ${percentChange.toStringAsFixed(0)}% decrease'
                        : 'Stable',
                    style: TextStyle(
                      color: hasIncrease 
                        ? Colors.green 
                        : hasDecrease 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(chartPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Card Acquisitions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Not enough acquisition data',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add more cards with dates to see your collection growth over time',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getMonthColor(int month, ColorScheme colorScheme) {
    // Create a gradient of colors throughout the year
    final colors = [
      Colors.blue.shade400, // Jan
      Colors.indigo.shade400, // Feb
      Colors.purple.shade400, // Mar
      Colors.deepPurple.shade400, // Apr
      Colors.pink.shade400, // May
      Colors.red.shade400, // Jun
      Colors.deepOrange.shade400, // Jul
      Colors.orange.shade400, // Aug
      Colors.amber.shade400, // Sep
      Colors.yellow.shade700, // Oct
      Colors.lightGreen.shade600, // Nov
      Colors.green.shade500, // Dec
    ];
    
    return colors[(month - 1) % colors.length];
  }

  List<_AcquisitionPoint> _calculateAcquisitionData() {
    if (cards.isEmpty) return [];
    
    // Group cards by month and year
    final acquisitionMap = <String, int>{};
    final formatter = DateFormat('yyyy-MM');
    
    // Track if we have date information
    int cardsWithDates = 0;
    
    for (final card in cards) {
      if (card.dateAdded != null) {
        cardsWithDates++;
        final dateStr = formatter.format(card.dateAdded!);
        acquisitionMap[dateStr] = (acquisitionMap[dateStr] ?? 0) + 1;
      }
    }
    
    // If we have no dateAdded information at all, create a single data point for today
    if (acquisitionMap.isEmpty && cards.isNotEmpty) {
      final now = DateTime.now();
      final dateStr = formatter.format(now);
      acquisitionMap[dateStr] = cards.length;
      
      // Add a second dummy data point for the previous month to ensure we have 2+ points
      final lastMonth = DateTime(now.year, now.month-1);
      final lastMonthStr = formatter.format(lastMonth);
      acquisitionMap[lastMonthStr] = 0;
    }
    
    // If we have only one data point, add a second one to make a timeline
    if (acquisitionMap.length == 1) {
      final existingDate = DateTime.parse(acquisitionMap.keys.first + '-01');
      final prevMonth = DateTime(existingDate.year, existingDate.month-1);
      final prevMonthStr = formatter.format(prevMonth);
      acquisitionMap[prevMonthStr] = 0;
    }
    
    // Convert to sorted list of data points
    final sortedDates = acquisitionMap.keys.toList()..sort();
    
    // Fill in missing months between dates (this was already correct)
    final fullTimeline = <_AcquisitionPoint>[];
    for (int i = 0; i < sortedDates.length; i++) {
      final dateParts = sortedDates[i].split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final date = DateTime(year, month);
      
      fullTimeline.add(_AcquisitionPoint(
        date: date,
        y: acquisitionMap[sortedDates[i]]!,
      ));
    }
    
    return fullTimeline;
  }
}

class _AcquisitionPoint {
  final DateTime date;
  final int y;
  
  _AcquisitionPoint({required this.date, required this.y});
}
