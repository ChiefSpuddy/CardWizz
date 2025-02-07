import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show max, min;  // Add min here
import 'package:flutter/gestures.dart';  // Add this import for PointerExitEvent
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../widgets/animated_background.dart';
import '../providers/currency_provider.dart';
import '../widgets/sign_in_view.dart';
import '../providers/app_state.dart';
import '../widgets/app_drawer.dart';  // Add this if it's missing
import '../l10n/app_localizations.dart';  // Add this import
import '../screens/card_details_screen.dart';  // Add this import
import 'dart:ui';  // Add this for ImageFilter
import '../services/purchase_service.dart';  // Add this import
import 'package:flutter/services.dart'; // Add this import at the top
import '../screens/home_screen.dart';  // Add this import at the top with other imports
import '../constants/layout.dart';  // Add this import
import '../widgets/price_update_dialog.dart';
import '../services/dialog_manager.dart';  // Add this import
import '../services/dialog_service.dart';
import '../utils/hero_tags.dart';  // Add this import
import '../services/analytics_service.dart';  // Add this import
import '../services/ebay_api_service.dart';  // Add this import

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  // Add dialog state tracking
  bool _isDialogVisible = false;
  BuildContext? _dialogContext;
  StreamSubscription? _progressSubscription;
  StreamSubscription? _completeSubscription;

  // Add this field
  bool _isLoadingMarketData = false;
  Map<String, dynamic>? _marketInsights;
  Map<String, dynamic>? _marketActivity;

  @override
  void initState() {
    super.initState();
    _updateLastRefreshTime();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _completeSubscription?.cancel();
    super.dispose();
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
                    builder: (context) => CardDetailsScreen(
                      card: card,
                      heroContext: 'analytics',  // Add this line
                    ),
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
                        tag: HeroTags.cardImage(card.id, context: 'analytics_top'),
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

    // Create timeline of portfolio value changes
    final timelinePoints = <DateTime, double>{};
    
    // First, get all unique dates from price histories
    final allDates = cards.expand((card) => 
      card.priceHistory.map((p) => DateTime(
        p.date.year, 
        p.date.month, 
        p.date.day,
        p.date.hour,  // Include hour for more granular data points
      ))
    ).toSet().toList()
      ..sort();

    // For each date, calculate total portfolio value
    for (final date in allDates) {
      double totalValue = 0;
      for (final card in cards) {
        // Find price closest to this date
        final pricePoint = card.priceHistory
            .where((p) => p.date.isBefore(date) || p.date.isAtSameMomentAs(date))
            .lastOrNull;
        
        if (pricePoint != null) {
          totalValue += pricePoint.price;
        }
      }
      timelinePoints[date] = totalValue;
    }

    if (timelinePoints.isEmpty) return const SizedBox.shrink();

    final maxY = timelinePoints.values.reduce(max);
    final minY = timelinePoints.values.reduce(min);
    final padding = maxY * 0.1;

    // Convert to spots for the chart
    final chartSpots = timelinePoints.entries.map((entry) {
      return FlSpot(
        entry.key.millisecondsSinceEpoch.toDouble(),
        entry.value,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16), // Reduced horizontal padding from 16 to 8
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
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Theme.of(context).colorScheme.surface,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                          return LineTooltipItem(
                            '${_formatDate(date)}\n${currencyProvider.formatValue(spot.y)}',
                            TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    getTouchLineStart: (data, index) => -padding,
                    getTouchLineEnd: (data, index) => maxY + padding,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,  // Show vertical grid lines
                    horizontalInterval: maxY / 4,
                    verticalInterval: const Duration(days: 7).inMilliseconds.toDouble(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
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
                        reservedSize: 46,
                        interval: maxY / 4,
                        getTitlesWidget: (value, _) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            currencyProvider.formatChartValue(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: minY,
                  maxY: maxY + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartSpots,
                      isCurved: true,
                      curveSmoothness: 0.5, // Increased from 0.35
                      preventCurveOverShooting: false, // Changed to false to allow smoother curves
                      color: Colors.green.shade600,
                      barWidth: 2.5, // Slightly increased for better visibility
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.green.shade600,
                          );
                        },
                      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year) {
      return '${date.day}/${date.month}';
    }
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }

  Widget _buildSetDistribution(List<TcgCard> cards) {
    final purchaseService = context.watch<PurchaseService>();
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get sorted sets
    final sortedSets = _getSetDistribution(cards);
    final totalCards = cards.length;
    final displaySets = sortedSets.take(6).toList(); // Show top 6 sets

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (purchaseService.isPremium) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set Distribution',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${sortedSets.length} sets total',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.pie_chart),
                        onPressed: () => _showDetailedSetAnalysis(context, sortedSets, totalCards),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...displaySets.map((set) {
                    final percentage = (set.value / totalCards * 100);
                    final index = displaySets.indexOf(set);
                    final color = _getSetColor(index);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  set.key,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '${set.value} cards',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 1000 + (index * 200)),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0, end: percentage),
                                builder: (context, value, child) => FractionallySizedBox(
                                  widthFactor: value / 100,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withOpacity(0.7),
                                          color,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  if (sortedSets.length > displaySets.length) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showDetailedSetAnalysis(context, sortedSets, totalCards),
                        icon: const Icon(Icons.analytics_outlined),
                        label: Text('View All ${sortedSets.length} Sets'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else
            _buildPremiumOverlay(purchaseService),
        ],
      ),
    );
  }

  Color _getSetColor(int index) {
    final colors = [
      const Color(0xFF4CAF50),  // Green
      const Color(0xFF2196F3),  // Blue
      const Color(0xFFFFA726),  // Orange
      const Color(0xFFE91E63),  // Pink
      const Color(0xFF9C27B0),  // Purple
      const Color(0xFF00BCD4),  // Cyan
    ];
    return colors[index % colors.length];
  }

  void _showDetailedSetAnalysis(
    BuildContext context,
    List<MapEntry<String, int>> sets,
    int totalCards,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: CustomScrollView(
                  controller: controller,
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Set Distribution Analysis',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final set = sets[index];
                            final percentage = (set.value / totalCards * 100);
                            final color = _getSetColor(index);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          set.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${set.value} cards (${percentage.toStringAsFixed(1)}%)',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: sets.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRangeDistribution(List<TcgCard> cards) {
  final purchaseService = context.watch<PurchaseService>();
  final currencyProvider = context.watch<CurrencyProvider>();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Simplified price ranges
  final ranges = [
    (0.0, 1.0, 'Budget'),
    (1.0, 5.0, 'Common'),
    (5.0, 15.0, 'Uncommon'),
    (15.0, 50.0, 'Rare'),
    (50.0, 100.0, 'Super Rare'),
    (100.0, double.infinity, 'Ultra Rare'),
  ];

  // Calculate distribution
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

  final maxCount = distribution.reduce(max);

  return Card(
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(ranges.length, (index) {
                final count = distribution[index];
                if (count == 0) return const SizedBox.shrink();

                final percentage = count / cards.length * 100;
                final range = ranges[index];
                final color = [
                  Colors.grey,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.orange,
                  Colors.red,
                ][index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              range.$3,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$count cards',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: count / maxCount,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color.withOpacity(0.7),
                                            color,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyProvider.symbol}${range.$1.toStringAsFixed(0)}'
                        '${range.$2 < double.infinity ? ' - ${currencyProvider.symbol}${range.$2.toStringAsFixed(0)}' : '+'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        if (!purchaseService.isPremium)
          Positioned.fill(
            child: _buildPremiumOverlay(purchaseService),
          ),
      ],
    ),
  );
}

  Widget _buildTopMovers(List<TcgCard> cards) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final localizations = AppLocalizations.of(context);
    
    // Calculate changes for all periods at once
    final cardsWithChanges = cards
        .where((card) => card.price != null && card.priceHistory.length >= 2)
        .map((card) {
          // Try daily change first
          var change = card.getPriceChange(const Duration(days: 1));
          var period = '24h';
          
          // If no daily change, try weekly
          if (change == null || change == 0) {
            change = card.getPriceChange(const Duration(days: 7));
            period = '7d';
          }
          
          // If still no change, try monthly
          if (change == null || change == 0) {
            change = card.getPriceChange(const Duration(days: 30));
            period = '30d';
          }
          
          return (card, change, period);
        })
        .where((tuple) => tuple.$2 != null && tuple.$2 != 0) // Filter out null and 0 changes
        .toList()
        ..sort((a, b) => (b.$2 ?? 0).abs().compareTo((a.$2 ?? 0).abs()));

    // Debug print
    print('Found ${cardsWithChanges.length} cards with price changes');
    for (final (card, change, period) in cardsWithChanges.take(5)) {
      print('${card.name}: ${change?.toStringAsFixed(1)}% ($period) - Price: ${card.price}, History: ${card.priceHistory.length} entries');
    }

    if (cardsWithChanges.isEmpty) {
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
                child: Column(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No price changes detected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final topMovers = cardsWithChanges.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fix the overflowing row
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  localizations.translate('topMovers'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Based on recent changes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topMovers.map((tuple) {
              final card = tuple.$1;
              final change = tuple.$2 ?? 0;
              final period = tuple.$3;
              final isPositive = change >= 0;
              
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardDetailsScreen(
                      card: card,
                      heroContext: 'analytics',
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Hero(
                          tag: HeroTags.cardImage(card.id, context: 'analytics_movers_${card.id}'),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              currencyProvider.formatValue(card.price ?? 0),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildChangeIndicator(change),
                          const SizedBox(height: 4),
                          Text(
                            period,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
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
    if (!mounted) return;
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final dialogManager = DialogManager.instance;
      
      // Cancel existing subscriptions
      _progressSubscription?.cancel();
      _completeSubscription?.cancel();

      await storage.initializeBackgroundService();
      final service = storage.backgroundService;
      if (service == null) {
        throw Exception('Failed to initialize background service');
      }

      // Show initial dialog
      if (!dialogManager.isDialogVisible && mounted) {
        dialogManager.showCustomDialog(
          PriceUpdateDialog(current: 0, total: 1),
        );
      }

      // Listen for progress updates
      _progressSubscription = storage.priceUpdateProgress.listen((progress) {
        final (current, total) = progress;
        dialogManager.updateDialog(
          PriceUpdateDialog(current: current, total: total),
        );
      });

      // Listen for completion
      _completeSubscription = storage.priceUpdateComplete.listen((updatedCount) {
        dialogManager.hideDialog();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated prices for $updatedCount cards'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

      await service.refreshPrices();
      await _updateLastRefreshTime();
      
    } catch (e) {
      print('Error refreshing prices: $e');
      DialogManager.instance.hideDialog();
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

  Widget _buildMarketInsightsCard(List<TcgCard> cards) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Market Insights',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoadingMarketData)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _loadMarketData(cards),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_marketInsights != null) ...[
              _buildMarketStat(
                'Total Active Listings',
                '${_marketInsights!['totalListings']}',
                Icons.store,
              ),
              _buildMarketStat(
                'Average Market Price',
                context.read<CurrencyProvider>().formatValue(_marketInsights!['averagePrice']),
                Icons.payments,
              ),
              const SizedBox(height: 16),
              Text(
                'Market Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_marketActivity != null)
                Row(
                  children: [
                    _buildActivityIndicator(
                      'Last 24h',
                      _marketActivity!['last_24h'] ?? 0,
                      Colors.green,
                    ),
                    _buildActivityIndicator(
                      'Last Week',
                      _marketActivity!['last_week'] ?? 0,
                      Colors.blue,
                    ),
                    _buildActivityIndicator(
                      'Last Month',
                      _marketActivity!['last_month'] ?? 0,
                      Colors.purple,
                    ),
                  ],
                ),
            ] else
              Center(
                child: TextButton.icon(
                  onPressed: () => _loadMarketData(cards),
                  icon: const Icon(Icons.update),
                  label: const Text('Load Market Data'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
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

  Widget _buildActivityIndicator(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMarketData(List<TcgCard> cards) async {
    if (_isLoadingMarketData) return;
    
    setState(() => _isLoadingMarketData = true);
    
    try {
      final ebayService = EbayApiService();
      final cardNames = cards.map((c) => c.name).toList();
      
      final insights = await ebayService.getMarketInsights(cardNames);
      final activity = await ebayService.getMarketActivity(cardNames);
      
      if (mounted) {
        setState(() {
          _marketInsights = insights;
          _marketActivity = activity;
          _isLoadingMarketData = false;
        });
      }
    } catch (e) {
      print('Error loading market data: $e');
      if (mounted) {
        setState(() => _isLoadingMarketData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(), // Update this line
        ),
        actions: isSignedIn ? [  // Add this condition
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
        ] : null,  // Return null when not signed in
      ),
      drawer: const AppDrawer(),  // Remove scaffoldKey parameter
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,  // Add this
                              children: [
                                _buildValueSummary(cards),
                                const SizedBox(height: 12),
                                _buildValueTrendCard(cards),
                                const SizedBox(height: 16),
                                _buildMarketInsightsCard(cards), // Add this line
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
    final weeklyChange = 5.8;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('portfolioValue'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyProvider.formatValue(totalValue),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${weeklyChange.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildPremiumOverlay(PurchaseService purchaseService) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => purchaseService.purchasePremium(),
            child: Center( // Added Center widget
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300), // Added constraints
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Premium Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock detailed collection insights\nand advanced analytics',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => purchaseService.purchasePremium(),
                        icon: const Text('✨'),
                        label: const Text('Upgrade to Premium'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

