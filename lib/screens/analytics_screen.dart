import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max;
import 'package:flutter/gestures.dart';  // Add this import for PointerExitEvent
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../widgets/animated_background.dart';
import '../providers/currency_provider.dart';
import '../widgets/sign_in_view.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';  // Add this import
import '../screens/card_details_screen.dart';  // Add this import
import 'dart:ui';  // Add this for ImageFilter
import '../services/purchase_service.dart';  // Add this import

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Add these properties at the top of the class
  static const int initialDisplayCount = 5;
  final List<Color> colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  List<MapEntry<String, int>> _getSetDistribution(List<TcgCard> cards) {
    // Group cards by set
    final setMap = <String, int>{};
    for (final card in cards) {
      final set = card.setName ?? 'Unknown Set';
      setMap[set] = (setMap[set] ?? 0) + 1;
    }

    // Sort sets by card count
    final sortedSets = setMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSets;
  }

  Widget _buildOverviewCard(List<TcgCard> cards) {
    final localizations = AppLocalizations.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();
    final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
    final mostValuableCard = cards.reduce((a, b) => 
      (a.price ?? 0) > (b.price ?? 0) ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('collectionOverview'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Value', currencyProvider.formatValue(totalValue)),
            _buildStatRow('Total Cards', '${cards.length} cards'),
            _buildStatRow('Most Valuable', 
              '${mostValuableCard.name} (${currencyProvider.formatValue(mostValuableCard.price ?? 0)})'),
            _buildStatRow('Average Value', 
              currencyProvider.formatValue(totalValue / cards.length)),
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
    final localizations = AppLocalizations.of(context);
    final timeframes = {
      localizations.translate('timeframe_24h'): 2.5,
      localizations.translate('timeframe_7d'): 5.8,
      localizations.translate('timeframe_30d'): 15.2,
      localizations.translate('timeframe_YTD'): 45.7,
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
    final localizations = AppLocalizations.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();
    final sortedCards = List<TcgCard>.from(cards)
      ..sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    final topCards = sortedCards.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('mostValuable'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topCards.map((card) => InkWell( // Add InkWell here
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardDetailsScreen(card: card),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Hero( // Add Hero widget for smooth transition
                      tag: 'analytics_card_${card.id}', // Updated unique tag
                      child: Image.network(
                        card.imageUrl,
                        height: 50,
                        width: 36,
                        fit: BoxFit.contain,
                      ),
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
                            card.rarity ?? localizations.translate('unknownRarity'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyProvider.formatValue(card.price ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTrendCard(List<TcgCard> cards) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final localizations = AppLocalizations.of(context);
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

    final spots = List.generate(valuePoints.length, (i) {
      // Add proper rounding to 2 decimal places
      final roundedValue = double.parse(valuePoints[i].toStringAsFixed(2));
      return FlSpot(i.toDouble(), roundedValue);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('valueOverTime'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyProvider.formatValue(maxY),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
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
                        interval: max(1, valuePoints.length / 4).toDouble(),
                        getTitlesWidget: (value, _) {
                          if (value.toInt() >= valuePoints.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.now().subtract(
                            Duration(days: valuePoints.length - 1 - value.toInt())
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                fontSize: 12,
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
                        interval: maxY / 4,
                        getTitlesWidget: (value, _) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            currencyProvider.formatChartValue(value.toInt().toDouble()),  // Convert to int
                            style: TextStyle(
                              fontSize: 10,  // Reduced from 12
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: maxY + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      color: Colors.green.shade600,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.shade600.withOpacity(0.2),
                            Colors.green.shade600.withOpacity(0.0),
                          ],
                        ),
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
    final purchaseService = context.watch<PurchaseService>();
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get sorted sets
    final sortedSets = _getSetDistribution(cards);
    final hasMore = sortedSets.length > initialDisplayCount;

    return Stack(
      children: [
        Card(
          // Existing card content, but blur it when not premium
          child: ImageFiltered(
            imageFilter: purchaseService.isPremium 
                ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                : ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Opacity(
              opacity: purchaseService.isPremium ? 1.0 : 0.7,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          localizations.translate('setDistribution'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${sortedSets.length} ${localizations.translate('sets')}',
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
                      height: 140,  // Reduced height
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sections: sortedSets.take(initialDisplayCount).toList().asMap().entries.map((entry) {
                                  final percentage = (entry.value.value / cards.length * 100).toStringAsFixed(1);
                                  return PieChartSectionData(
                                    color: colors[entry.key % colors.length],
                                    value: entry.value.value.toDouble(),
                                    title: '$percentage%',
                                    radius: 60,  // Fixed smaller radius
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    titlePositionPercentageOffset: 0.55,
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Single legend
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (Rect rect) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.purple.withOpacity(0),
                                    Colors.purple.withOpacity(1),
                                  ],
                                  stops: const [0.9, 1.0],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstOut,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: sortedSets.take(initialDisplayCount).toList().asMap().entries.map((entry) {
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
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.outline,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${entry.value.key}\n${entry.value.value} cards ($percentage%)',
                                              style: const TextStyle(fontSize: 12),
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasMore) ...[
                      const SizedBox(height: 16),
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
            ),
          ),
        ),
        
        // Premium lock overlay
        if (!purchaseService.isPremium)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  try {
                    await purchaseService.purchasePremium();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Premium Feature',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock detailed set analytics\nand more with Premium',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => purchaseService.purchasePremium(),
                        icon: const Text('💎'),
                        label: const Text('Upgrade Now'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
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
                  );  // Add semicolon here
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeDistribution(List<TcgCard> cards) {
    final purchaseService = context.watch<PurchaseService>();
    final localizations = AppLocalizations.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Updated price ranges with more detail
    final ranges = [
      (0.0, 1.0, '< ${currencyProvider.symbol}1'),
      (1.0, 5.0, '${currencyProvider.symbol}1-5'),
      (5.0, 10.0, '${currencyProvider.symbol}5-10'),
      (10.0, 25.0, '${currencyProvider.symbol}10-25'),
      (25.0, 50.0, '${currencyProvider.symbol}25-50'),
      (50.0, 100.0, '${currencyProvider.symbol}50-100'),
      (100.0, 200.0, '${currencyProvider.symbol}100-200'),
      (200.0, 500.0, '${currencyProvider.symbol}200-500'),
      (500.0, double.infinity, '${currencyProvider.symbol}500+'),
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

    return Stack(
      children: [
        Card(
          child: ImageFiltered(
            imageFilter: purchaseService.isPremium 
                ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                : ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Opacity(
              opacity: purchaseService.isPremium ? 1.0 : 0.7,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          localizations.translate('priceRange'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${localizations.translate('total')}: ${cards.length} ${localizations.translate('cards')}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 240, // Increased height
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8), // Add padding for labels
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
                                    width: 20, // Slightly reduced width
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 5,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40, // More space for labels
                                  interval: 1,
                                  getTitlesWidget: (value, _) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Transform.rotate(
                                        angle: -0.5, // Angle labels slightly
                                        child: Text(
                                          ranges[value.toInt()].$3,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 5,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Theme.of(context).dividerColor.withOpacity(0.2),
                                strokeWidth: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Premium lock overlay
        if (!purchaseService.isPremium)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  try {
                    await purchaseService.purchasePremium();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.query_stats,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Premium Feature',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock detailed price analytics\nand collection insights',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => purchaseService.purchasePremium(),
                        icon: const Text('💎'),
                        label: const Text('Upgrade Now'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: !isSignedIn
              ? const SignInView()
              : StreamBuilder<List<TcgCard>>(
                  stream: Provider.of<StorageService>(context).watchCards(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final cards = snapshot.data!;
                    if (cards.isEmpty) {
                      return Center(
                        child: Text(localizations.translate('addCardsForAnalytics')),
                      );
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          title: Text(localizations.translate('analytics')),
                          pinned: true,
                          floating: true,
                        ),
                        SliverToBoxAdapter(
                          child: Padding(  // Add this Padding widget
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _buildValueSummary(cards),
                                const SizedBox(height: 16),
                                _buildValueTrendCard(cards),
                                const SizedBox(height: 16),
                                _buildTopCardsCard(cards),
                                const SizedBox(height: 16),
                                _buildTopMovers(cards),  // This should now be visible
                                const SizedBox(height: 16),
                                _buildSetDistribution(cards),
                                const SizedBox(height: 16),
                                _buildPriceRangeDistribution(cards),
                                const SizedBox(height: 32),  // Add bottom padding
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
    final currencyProvider = context.watch<CurrencyProvider>();
    final localizations = AppLocalizations.of(context);
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
                  localizations.translate('portfolioValue'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildChangeIndicator(weeklyChange),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyProvider.formatValue(totalValue),
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
    final currencyProvider = context.watch<CurrencyProvider>();
    print('Building top movers with ${cards.length} cards');
    
    // Get cards with price history
    final cardsWithHistory = cards.where((card) => 
      card.price != null && card.priceHistory.isNotEmpty
    ).toList();
    print('Cards with history: ${cardsWithHistory.length}');

    // Always create changes list, even with one card
    final changes = cardsWithHistory.map((card) {
      final currentPrice = card.price!;
      final oldPrice = card.priceHistory.first.price;
      final percentageChange = ((currentPrice - oldPrice) / oldPrice) * 100;
      
      return PriceChange(
        card: card,
        currentPrice: currentPrice,
        previousPrice: oldPrice,
        percentageChange: double.parse(percentageChange.toStringAsFixed(2)),
      );
    }).toList();

    print('Found ${changes.length} price changes');

    // Sort by absolute percentage change
    changes.sort((a, b) => b.percentageChange.abs().compareTo(a.percentageChange.abs()));
    
    final topChanges = changes.take(changes.length).toList(); // Show all changes
    final hasMore = changes.length > 3;

    // Always return the card widget
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Movers (24h)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                currencyProvider.formatValue(change.currentPrice),
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
    final currencyProvider = context.watch<CurrencyProvider>();  // Add this line
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final currencyProvider = context.watch<CurrencyProvider>();  // Add this line inside builder
          return Column(
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
                        'Previous: ${currencyProvider.formatValue(change.previousPrice)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: _buildPriceChangeIndicator(
                        change.percentageChange,
                        currencyProvider.formatValue(change.currentPrice),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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
            // Make background more opaque
            color: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              // Use more contrasting colors
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isPositive ? Colors.green : Colors.red).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
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

