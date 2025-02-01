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
import 'package:flutter/services.dart'; // Add this import at the top
import '../screens/home_screen.dart';  // Add this import at the top with other imports
import '../constants/layout.dart';  // Add this import

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

  bool _isRefreshing = false;
  DateTime? _lastUpdateTime;

  // Add this getter
  AppLocalizations get localizations => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _updateLastRefreshTime();
  }

  Future<void> _updateLastRefreshTime() async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final time = await storage.backgroundService?.getLastUpdateTime();
    if (mounted) {
      setState(() => _lastUpdateTime = time);
    }
  }

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
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(  // Changed from Text to Flexible
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Add helper method for better text overflow handling
  Widget _buildValueText(String text, {TextStyle? style}) {
    return Flexible(
      child: Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
                    SizedBox(
                      width: 28,
                      child: Hero(
                        tag: 'card_${card.id}',  // Updated unique tag
                        child: _buildCardImage(card.imageUrl),
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
    
    if (cards.length < 2) {
      return Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.show_chart,
                  size: 48,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.translate('needMoreCards'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
          child: SingleChildScrollView( // Add this to prevent overflow
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

  Widget _buildTopMovers(List<TcgCard> cards) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final localizations = AppLocalizations.of(context);
    
    // Filter cards with price history
    final cardsWithHistory = cards.where((card) => 
      card.price != null && card.priceHistory.isNotEmpty
    ).toList();
    
    // Show placeholder if no price history
    if (cardsWithHistory.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('topMovers'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Updates run daily. Last checked: ${_lastUpdateTime != null 
                      ? _formatDateTime(_lastUpdateTime!) 
                      : 'Not yet'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Rest of existing _buildTopMovers implementation
    // ...

    // Calculate 24h changes
    final periodChanges = cardsWithHistory.map((card) {
      final change = card.getPriceChange(const Duration(hours: 24));
      return (card, change);
    }).where((tuple) => tuple.$2 != null)
      .toList()
      ..sort((a, b) => (b.$2 ?? 0).abs().compareTo((a.$2 ?? 0).abs()));

    final topMovers = periodChanges.take(5).toList();
    
    if (topMovers.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('topMovers'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topMovers.map((tuple) {
              final card = tuple.$1;
              final change = tuple.$2 ?? 0;
              final isPositive = change >= 0;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 28, // Fixed width for image
                  child: Hero(
                    tag: 'mover_${card.id}',  // Different tag for top movers
                    child: _buildCardImage(card.imageUrl),
                  ),
                ),
                title: _buildValueText(card.name),  // Use helper method
                subtitle: _buildValueText(
                  currencyProvider.formatValue(card.price ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardDetailsScreen(card: card),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPrices() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      if (storage.backgroundService != null) {
        await storage.backgroundService!.refreshPrices();
        await _updateLastRefreshTime();  // Add this line
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              'Prices updated successfully. Changes will appear in Top Movers after 24 hours'
            )),
          );
        }
      } else {
        throw Exception('Background service not initialized');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating prices: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height * LayoutConstants.emptyStatePaddingBottom,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.query_stats,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                localizations.translate('noAnalyticsYet'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('addCardsForAnalytics'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  final homeState = context.findAncestorStateOfType<HomeScreenState>();
                  homeState?.setSelectedIndex(2); // Navigate to search tab
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Cards'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          Tooltip(
            message: _lastUpdateTime != null 
              ? 'Last updated: ${_formatDateTime(_lastUpdateTime!)}\nTap to check for new prices'
              : 'Tap to check for new prices',
            waitDuration: const Duration(milliseconds: 500),
            showDuration: const Duration(seconds: 2),
            preferBelow: false,
            child: IconButton(
              icon: _isRefreshing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 22),
              onPressed: _isRefreshing ? null : _refreshPrices,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                      return _buildEmptyState();
                    }

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _buildValueSummary(cards),
                                const SizedBox(height: 12),
                                _buildValueTrendCard(cards),
                                const SizedBox(height: 16),
                                _buildTopMovers(cards),
                                const SizedBox(height: 16),
                                _buildTopCardsCard(cards),
                                const SizedBox(height: 16),
                                _buildSetDistribution(cards),
                                const SizedBox(height: 16),
                                _buildPriceRangeDistribution(cards),
                                const SizedBox(height: 32),
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

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
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
      ),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Add this helper method to handle image errors
  Widget _buildCardImage(String imageUrl) {
    return Image.network(
      imageUrl,
      height: 40,
      width: 28,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 28,  // Fixed width
          height: 40,  // Fixed height
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.broken_image_outlined,
            size: 20,  // Smaller icon
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

