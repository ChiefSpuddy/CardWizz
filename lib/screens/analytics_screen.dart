import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../widgets/animated_background.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _formatValue(double value) {
    if (value >= 1000000) {
      return '€${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '€${(value / 1000).toStringAsFixed(1)}K';
    }
    return '€${value.toStringAsFixed(2)}';
  }

  Widget _buildOverviewCard(List<TcgCard> cards) {
    final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
    final mostValuableCard = cards.reduce((a, b) => 
      (a.price ?? 0) > (b.price ?? 0) ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Collection Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Value', _formatValue(totalValue)),
            _buildStatRow('Total Cards', '${cards.length} cards'),
            _buildStatRow('Most Valuable', 
              '${mostValuableCard.name} (${_formatValue(mostValuableCard.price ?? 0)})'),
            _buildStatRow('Average Value', 
              _formatValue(totalValue / cards.length)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFrameCard(List<TcgCard> cards) {
    final timeframes = {
      '24h': 2.5,
      '7d': 5.8,
      '30d': 15.2,
      'YTD': 45.7,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Value Growth',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: timeframes.entries.map((entry) {
                final isPositive = entry.value >= 0;
                return Expanded(
                  child: Card(
                    color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    child: Container(
                      height: 64,  // Fixed height
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '${isPositive ? '+' : ''}${entry.value}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isPositive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCardsCard(List<TcgCard> cards) {
    final sortedCards = List<TcgCard>.from(cards)
      ..sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    final topCards = sortedCards.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Valuable Cards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topCards.map((card) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Image.network(
                    card.imageUrl,
                    height: 50,
                    width: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          card.rarity ?? 'Unknown Rarity',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatValue(card.price ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTrendCard(List<TcgCard> cards) {
    if (cards.isEmpty) return const SizedBox.shrink();

    // Sort cards by value for trend analysis
    final sortedCards = List<TcgCard>.from(cards)..sort((a, b) => 
      (a.price ?? 0).compareTo(b.price ?? 0));
    
    double runningTotal = 0;
    final valuePoints = sortedCards
        .where((card) => card.price != null)
        .map((card) {
          runningTotal += card.price!;
          return runningTotal;
        })
        .toList();

    if (valuePoints.isEmpty) return const SizedBox.shrink();

    final maxY = valuePoints.last;
    final minY = 0.0;
    final padding = maxY * 0.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Collection Growth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatValue(maxY),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(1, (valuePoints.length / 5).floor()).toDouble(),
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt() + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: maxY / 5,
                        getTitlesWidget: (value, _) => Text(
                          _formatValue(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  minY: minY,
                  maxY: maxY + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: valuePoints.asMap().entries.map((entry) {
                        final roundedValue = double.parse(entry.value.toStringAsFixed(2));
                        return FlSpot(entry.key.toDouble(), roundedValue);
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: Colors.green,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetDistribution(List<TcgCard> cards) {
    // Group cards by set
    final setMap = <String, int>{};
    for (final card in cards) {
      final set = card.setName ?? 'Unknown Set';
      setMap[set] = (setMap[set] ?? 0) + 1;
    }

    // Sort sets by card count
    final sortedSets = setMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final initialDisplayCount = 5;
    final hasMore = sortedSets.length > initialDisplayCount;

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.primaryContainer,
      Theme.of(context).colorScheme.secondaryContainer,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Set Distribution',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${sortedSets.length} sets',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Pie Chart
            SizedBox(
              height: 160,  // Reduced from 200
              child: PieChart(
                PieChartData(
                  sections: sortedSets.take(initialDisplayCount).toList().asMap().entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value.value.toDouble(),
                      title: '',
                      radius: 70,  // Reduced from 100
                      color: colors[entry.key % colors.length],
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,  // Reduced from 40
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Legend
            ...sortedSets.take(initialDisplayCount).toList().asMap().entries.map((entry) {
              final percentage = (entry.value.value / cards.length * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[entry.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value.key,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value.value} (${percentage}%)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (hasMore) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _showAllSets(context, sortedSets, colors, cards.length),
                  child: Text('Show All Sets (${sortedSets.length})'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAllSets(
    BuildContext context,
    List<MapEntry<String, int>> sets,
    List<Color> colors,
    int totalCards,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'All Sets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: sets.length,
                itemBuilder: (context, index) {
                  final entry = sets[index];
                  final percentage = (entry.value / totalCards * 100).toStringAsFixed(1);
                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(entry.key),
                    trailing: Text(
                      '${entry.value} (${percentage}%)',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeDistribution(List<TcgCard> cards) {
    final ranges = [
      (0.0, 1.0, '< €1'),
      (1.0, 5.0, '€1-5'),
      (5.0, 10.0, '€5-10'),
      (10.0, 50.0, '€10-50'),
      (50.0, double.infinity, '> €50'),
    ];

    final distribution = List.filled(ranges.length, 0);
    for (final card in cards) {
      final price = card.price ?? 0;
      for (var i = 0; i < ranges.length; i++) {
        if (price >= ranges[i].$1 && price < ranges[i].$2) {
          distribution[i]++;
          break;
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Price Distribution',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'Total: ${cards.length} cards',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: distribution.reduce(max).toDouble(),
                  barGroups: distribution.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 24,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              ranges[value.toInt()].$3,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 5,
                        getTitlesWidget: (value, _) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: StreamBuilder<List<TcgCard>>(
            stream: Provider.of<StorageService>(context).watchCards(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final cards = snapshot.data!;
              if (cards.isEmpty) {
                return const Center(
                  child: Text('Add some cards to see analytics'),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: const Text('Analytics'),
                    pinned: true,
                    floating: true,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildValueSummary(cards),
                          const SizedBox(height: 16),
                          _buildValueTrendCard(cards),
                          const SizedBox(height: 16),
                          _buildTopCardsCard(cards),  // Moved up
                          const SizedBox(height: 16),
                          _buildSetDistribution(cards),
                          const SizedBox(height: 16),
                          _buildPriceRangeDistribution(cards),
                          const SizedBox(height: 16),
                          _buildTopMovers(cards),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildValueSummary(List<TcgCard> cards) {
    final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
    final weeklyChange = 5.8; // TODO: Implement real calculation

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Portfolio Value',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildChangeIndicator(weeklyChange),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatValue(totalValue),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMovers(List<TcgCard> cards) {
    // Use real price history for calculations
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    
    final changes = cards.where((card) => card.price != null && card.priceHistory.isNotEmpty)
      .map((card) {
        // Find the price from ~24 hours ago
        final previousPrice = card.priceHistory
          .lastWhere(
            (entry) => entry.date.isBefore(oneDayAgo),
            orElse: () => PriceHistoryEntry(
              date: oneDayAgo,
              price: card.price! * 0.95  // Fallback: assume 5% change if no history
            ),
          ).price;

        final percentageChange = ((card.price! - previousPrice) / previousPrice) * 100;
        return PriceChange(
          card: card,
          currentPrice: card.price!,
          previousPrice: previousPrice,
          percentageChange: percentageChange,
        );
      })
      .where((change) => change.percentageChange.abs() > 0)  // Only show cards with price changes
      .toList()
      ..sort((a, b) => b.percentageChange.abs().compareTo(a.percentageChange.abs()));

    final topChanges = changes.take(3).toList();
    final hasMore = changes.length > 3;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Top Movers (24h)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (hasMore)
                  TextButton(
                    onPressed: () => _showAllMovers(context, topChanges),
                    child: const Text('Show All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...topChanges.map((change) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Image.network(
                change.card.imageUrl,
                height: 40,
                width: 28,
                fit: BoxFit.contain,
              ),
              title: Text(change.card.name),
              trailing: _buildPriceChangeIndicator(
                change.percentageChange,
                _formatValue(change.currentPrice),
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<PriceChange> _calculatePriceChanges(List<TcgCard> cards) {
    final changes = <PriceChange>[];
    final now = DateTime.now();
    
    for (final card in cards) {
      if (card.price != null && card.priceHistory.isNotEmpty) {
        // Find the most recent price within the last 24 hours
        final recentPrice = card.priceHistory
            .where((entry) => now.difference(entry.date).inHours <= 24)
            .lastOrNull;
            
        if (recentPrice != null && recentPrice.price > 0) {
          final percentageChange = ((card.price! - recentPrice.price) / recentPrice.price) * 100;
          changes.add(PriceChange(
            card: card,
            currentPrice: card.price!,
            previousPrice: recentPrice.price,
            percentageChange: percentageChange,
          ));
        }
      }
    }
    
    return changes;
  }

  void _showAllMovers(BuildContext context, List<PriceChange> changes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'All Price Changes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: changes.length,
                itemBuilder: (context, index) {
                  final change = changes[index];
                  return ListTile(
                    leading: Image.network(
                      change.card.imageUrl,
                      height: 40,
                      width: 28,
                      fit: BoxFit.contain,
                    ),
                    title: Text(change.card.name),
                    subtitle: Text(
                      'Previous: ${_formatValue(change.previousPrice)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: _buildPriceChangeIndicator(
                      change.percentageChange,
                      _formatValue(change.currentPrice),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChangeIndicator(double percentage, String currentPrice) {
    final isPositive = percentage >= 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currentPrice,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildChangeIndicator(double change) {
    final isPositive = change >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isPositive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

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
