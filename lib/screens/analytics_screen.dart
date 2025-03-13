import '../services/logging_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import '../services/storage_service.dart';
import '../widgets/animated_background.dart';
import '../providers/currency_provider.dart';
import '../widgets/sign_in_view.dart';
import '../providers/app_state.dart';
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../screens/card_details_screen.dart';
import 'dart:ui';
import '../services/purchase_service.dart';
import '../screens/home_screen.dart';
import '../constants/layout.dart';
import '../widgets/price_update_dialog.dart';
import '../services/dialog_manager.dart';
import '../services/dialog_service.dart';
import '../utils/hero_tags.dart';
import '../services/chart_service.dart';
import '../services/ebay_api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/empty_collection_view.dart';
import '../widgets/portfolio_value_chart.dart';
import '../widgets/styled_toast.dart';
import 'package:rxdart/rxdart.dart';
import '../widgets/market_scan_button.dart';
import '../widgets/acquisition_timeline_chart.dart';
import '../widgets/rarity_distribution_chart.dart';
import '../widgets/price_update_button.dart';
import '../widgets/standard_app_bar.dart';
import '../services/analytics_cache_service.dart';
import '../models/tcg_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  static final _scrollController = ScrollController();
  
  static void scrollToTop(BuildContext context) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  AppLocalizations get localizations => AppLocalizations.of(context);

  bool _isDialogVisible = false;
  BuildContext? _dialogContext;
  StreamSubscription? _progressSubscription;
  StreamSubscription? _completeSubscription;

  bool _isLoadingMarketData = false;
  Map<String, dynamic>? _marketInsights;
  Map<String, dynamic>? _marketOpportunities;

  String? _marketDataError;
  int _loadingProgress = 0;
  int _totalCards = 0;

  List<Map<String, dynamic>>? _cachedTopMovers;
  bool _isLoadingTopMovers = false;
  final double _topMoversCardHeight = 360.0;

  final _analyticsCacheService = AnalyticsCacheService();
  DateTime? _cachedTopMoversTimestamp;

  @override
  void initState() {
    super.initState();
    _updateLastRefreshTime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DialogManager.instance.setContext(context);
      
      // Try to load cached top movers from the service
      final cachedMovers = _analyticsCacheService.getTopMovers();
      if (cachedMovers != null && cachedMovers.isNotEmpty) {
        setState(() {
          _cachedTopMovers = cachedMovers;
          _cachedTopMoversTimestamp = DateTime.now();
        });
      }
    });
    AnalyticsScreen._scrollController.addListener(_onScroll);
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
    final setMap = <String, int>{};
    for (final card in cards) {
      final set = card.setName ?? 'Unknown Set';
      setMap[set] = (setMap[set] ?? 0) + 1;
    }

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
          Flexible(
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
                      height: 64,
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
            ...topCards.map((card) => InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardDetailsScreen(
                      card: card,
                      heroContext: 'value_${card.id}',
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
                        tag: 'value_${card.id}',
                        child: _buildCardImage(card.imageUrl ?? ''),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface.withOpacity(0.95)
            : Theme.of(context).colorScheme.background.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Provider<List<TcgCard>>.value(
            value: cards,
            child: const FullWidthAnalyticsChart(),
          ),
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
    
    final sortedSets = _getSetDistribution(cards);
    final totalCards = cards.length;
    final displaySets = sortedSets.take(6).toList();

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
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFFA726),
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
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

  final ranges = [
    (0.0, 1.0, 'Budget'),
    (1.0, 5.0, 'Common'),
    (5.0, 15.0, 'Uncommon'),
    (15.0, 50.0, 'Rare'),
    (50.0, 100.0, 'Super Rare'),
    (100.0, double.infinity, 'Ultra Rare'),
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

  final maxCount = distribution.reduce(math.max);

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
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  LoggingService.debug('Building top movers with ${cards.length} cards, cached: ${_cachedTopMovers?.length ?? 0}');
  
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _isLoadingTopMovers 
            ? (_cachedTopMovers != null 
                ? Future.value(_cachedTopMovers!) // Only use cached data if it's not null
                : Future.value(<Map<String, dynamic>>[]))  // Return empty list instead of null
            : _getRecentPriceChanges(cards),
    builder: (context, snapshot) {
      // Determine card content based on state
      Widget cardContent;

      if (snapshot.connectionState == ConnectionState.waiting) {
        if (_cachedTopMovers != null && _cachedTopMovers!.isNotEmpty && _isLoadingTopMovers) {
          // Show cached content with loading overlay during updates
          LoggingService.debug('Showing cached top movers with loading overlay');
          cardContent = _buildTopMoversContent(_cachedTopMovers!, isLoading: true);
        } else {
          // Initial loading with placeholder
          LoggingService.debug('Showing top movers loading placeholder');
          cardContent = _buildTopMoversLoading();
        }
      }
      else if (snapshot.hasError) {
        LoggingService.debug('Error loading top movers: ${snapshot.error}');
        cardContent = Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }
      else {
        final changes = snapshot.data ?? [];
        LoggingService.debug('Got ${changes.length} top movers from future builder');
        
        if (changes.isNotEmpty) {
          _cachedTopMovers = changes;
          _cachedTopMoversTimestamp = DateTime.now();
        }
        
        if (changes.isEmpty) {
          LoggingService.debug('No top movers found, showing empty state');
          cardContent = _buildEmptyTopMovers();
        } else {
          LoggingService.debug('Showing ${changes.length} top movers');
          cardContent = _buildTopMoversContent(changes);
        }
      }

      // Wrap with a card of fixed height to prevent layout shifts
      return Card(
        color: isDarkMode 
            ? Theme.of(context).colorScheme.surface 
            : null,
        child: SizedBox(
          height: _topMoversCardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  localizations.translate('topMovers'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: cardContent,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildEmptyTopMovers() {
  return Center(
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
          'No recent price changes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Check back after the next price update',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildTopMoversLoading() {
  return ListView.builder(
    padding: const EdgeInsets.only(bottom: 8),
    itemCount: 5,
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 28,
              width: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildTopMoversContent(List<Map<String, dynamic>> changes, {bool isLoading = false}) {
  final currencyProvider = context.watch<CurrencyProvider>();
  
  return Stack(
    key: ValueKey('top_movers_content_$isLoading'),
    children: [
      ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: changes.length,
        itemBuilder: (context, index) {
          final item = changes[index];
          final card = item['card'] as TcgCard;
          final change = item['change'] as double;
          final period = item['period'];
          final changeAmount = item['changeAmount'] as double?;
          
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardDetailsScreen(
                  card: card,
                  heroContext: 'mover_${card.id}',
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Hero(
                      tag: 'mover_${card.id}',
                      child: _buildCardImage(card.imageUrl ?? ''),
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
                      _buildChangeIndicator(change, changeAmount, currencyProvider),
                      const SizedBox(height: 4),
                      Text(
                        _formatPricePeriod(period),
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
        },
      ),
      
      if (isLoading)
        Positioned.fill(
          child: Container(
            color: Theme.of(context).colorScheme.background.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Updating price changes...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

Future<List<Map<String, dynamic>>> _getRecentPriceChanges(List<TcgCard> cards) async {
  try {
    // Safely access cached data with null check
    final now = DateTime.now();
    if (_cachedTopMovers != null && 
        _cachedTopMovers!.isNotEmpty &&
        _cachedTopMoversTimestamp != null && 
        now.difference(_cachedTopMoversTimestamp!) < const Duration(minutes: 5)) {
      LoggingService.debug('Using cached top movers data from $_cachedTopMoversTimestamp');
      if (_isLoadingTopMovers) {
        return _cachedTopMovers!;
      }
    }
    
    LoggingService.debug('Analyzing ${cards.length} cards for recent price changes');
    
    final cardsWithChanges = <Map<String, dynamic>>[];
    
    // Count how many cards have price history for debugging
    int cardsWithHistory = 0;
    
    for (final card in cards) {
      // Check if card has price history
      if (card.priceHistory.isNotEmpty && card.price != null) {
        cardsWithHistory++;
        
        // Try to find the most recent price change
        double? percentChange;
        double? changeAmount;
        String period = '';
        
        // First check if there's a direct price change record
        if (card.previousPrice != null && card.previousPrice! > 0) {
          percentChange = ((card.price! - card.previousPrice!) / card.previousPrice!) * 100;
          changeAmount = card.price! - card.previousPrice!;
          period = 'Last update';
        }
        // Otherwise check historical price points
        else {
          // Look for price changes in different time periods
          final periods = [
            {'1d': const Duration(days: 1)},
            {'7d': const Duration(days: 7)},
            {'30d': const Duration(days: 30)},
          ];
          
          for (final p in periods) {
            final key = p.keys.first;
            final duration = p.values.first;
            
            // Find historical price point
            final historyPoint = card.priceHistory.where(
              (entry) => now.difference(entry.timestamp) <= duration && 
                        now.difference(entry.timestamp) > Duration.zero
            ).toList();
            
            if (historyPoint.isNotEmpty) {
              // Sort by timestamp to get the closest match
              historyPoint.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              final oldPrice = historyPoint.first.price;
              
              // Calculate percent change if we have valid prices
              if (oldPrice > 0 && card.price! > 0) {
                percentChange = ((card.price! - oldPrice) / oldPrice) * 100;
                changeAmount = card.price! - oldPrice;
                period = key;
                break; // Use the first valid change we find
              }
            }
          }
        }
        
        // Add card to result if we found a price change (using a lower threshold of 0.1%)
        if (percentChange != null && percentChange.abs() >= 0.1) {
          cardsWithChanges.add({
            'card': card,
            'change': percentChange,
            'changeAmount': changeAmount,
            'period': period,
          });
        }
      }
    }
    
    LoggingService.debug('Found ${cardsWithChanges.length} cards with price changes');
    
    // Sort by absolute percentage change (largest first)
    cardsWithChanges.sort((a, b) => 
      (b['change'] as double).abs().compareTo((a['change'] as double).abs()));
    
    // Take the top movers (up to 10)
    final topMovers = cardsWithChanges.take(10).toList();
    
    // Store result in cache
    if (topMovers.isNotEmpty) {
      _cachedTopMovers = topMovers;
      _cachedTopMoversTimestamp = now;
      _analyticsCacheService.cacheTopMovers(topMovers);
    }
    
    return topMovers;
  } catch (e) {
    LoggingService.debug('Error calculating price changes: $e');
    
    // Try to use cached data if available
    if (_cachedTopMovers != null && _cachedTopMovers!.isNotEmpty) {
      return _cachedTopMovers!;
    }
    
    // Return an empty list if no data available
    return [];
  }
}

Future<void> _refreshPrices() async {
  if (!mounted || _isRefreshing) return;
  setState(() => _isRefreshing = true);
  
  // Only clear caches after we've saved a reference to them
  final previousCachedTopMovers = _cachedTopMovers;
  
  try {
    final storage = Provider.of<StorageService>(context, listen: false);
    await storage.initializeBackgroundService();
    final service = storage.backgroundService;
    if (service == null) throw Exception('Failed to initialize background service');

    setState(() {
      _isLoadingTopMovers = true;
    });

    _progressSubscription?.cancel();
    _completeSubscription?.cancel();

    _progressSubscription = storage.priceUpdateProgress
        .distinct()
        .listen((progress) {
          final (current, total) = progress;
          if (mounted) {
            DialogService.instance.showPriceUpdateDialog(current, total);
          }
        });

    _completeSubscription = storage.priceUpdateComplete
        .listen((_) {
          if (mounted) {
            // Now we can safely clear the caches
            _analyticsCacheService.clearTopMoversCache();
            _cachedTopMovers = null;
            _cachedTopMoversTimestamp = null;
            
            setState(() {
              _isRefreshing = false;
              _isLoadingTopMovers = false;
              _updateLastRefreshTime();
            });
            
            final cards = storage.getCards().then((cards) {
              if (cards.isNotEmpty && mounted) {
                if (!_isLoadingMarketData) {
                  _loadMarketData(cards);
                }
              }
            });
          }
        });

    await service.refreshPrices();
  } catch (e) {
    LoggingService.debug('Error refreshing prices: $e');
    DialogService.instance.hideDialog();
    
    // Restore previous cached data on error
    _cachedTopMovers = previousCachedTopMovers;
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _isLoadingTopMovers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating prices: $e')),
      );
    }
  }
}

  Widget _buildEmptyState() {
    return const EmptyCollectionView(
      title: 'No Analytics Yet',
      message: 'Add cards to your collection to see insights',
      buttonText: 'Browse Cards',
      icon: Icons.query_stats,
    );
  }

  Widget _buildMarketInsightsCard(List<TcgCard> cards) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      color: isDarkMode ? Theme.of(context).colorScheme.surface : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode 
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Market Scanner',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Find selling opportunities and track market trends',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoadingMarketData)
                _buildLoadingState()
              else if (_marketDataError != null)
                _buildErrorState(_marketDataError!, () => _loadMarketData(cards))
              else if (_marketOpportunities != null)
                ..._buildOpportunities()
              else
                MarketScanButton(
                  onPressed: () => _loadMarketData(cards),
                  isLoading: _isLoadingMarketData,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final progress = _totalCards > 0 ? _loadingProgress / _totalCards : 0.0;
    final percentage = (progress * 100).toInt();
    
    return Column(
      children: [
        Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              if (_loadingProgress > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: double.infinity,
                  width: MediaQuery.of(context).size.width * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade600,
                        Colors.green.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade600.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              Center(
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: _loadingProgress > 0 && percentage > 50
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analyzing card $_loadingProgress of $_totalCards',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'This may take a few minutes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMarketData(List<TcgCard> cards) async {
    if (_isLoadingMarketData) return;
    
    final cachedData = _analyticsCacheService.getMarketInsights();
    if (cachedData != null) {
      setState(() {
        _marketOpportunities = cachedData;
        _isLoadingMarketData = false;
      });
      return;
    }
    
    setState(() {
      _isLoadingMarketData = true;
      _marketDataError = null;
      _loadingProgress = 0;
      _totalCards = cards.length;
    });
    
    try {
      final ebayService = EbayApiService();
      final opportunities = <String, List<Map<String, dynamic>>>{
        'undervalued': [],
        'overvalued': [],
      };

      const batchSize = 5;
      for (var i = 0; i < cards.length; i += batchSize) {
        final batch = cards.skip(i).take(batchSize).toList();
        final results = await ebayService.getMarketOpportunities(batch);
        
        final undervalued = (results['undervalued'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        final overvalued = (results['overvalued'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        
        opportunities['undervalued']!.addAll(undervalued);
        opportunities['overvalued']!.addAll(overvalued);
        
        if (mounted) {
          setState(() => _loadingProgress = math.min(i + batchSize, cards.length));
        }
      }

      if (mounted) {
        _analyticsCacheService.cacheMarketInsights(opportunities);
        
        setState(() {
          _marketOpportunities = opportunities;
          _isLoadingMarketData = false;
        });
      }
    } catch (e) {
      LoggingService.debug('Error loading market data: $e');
      if (mounted) {
        setState(() {
          _marketDataError = 'Failed to load market data. Please try again.';
          _isLoadingMarketData = false;
        });
      }
    }
  }

  List<Widget> _buildOpportunities() {
  final opportunities = _marketOpportunities!;
  final widgets = <Widget>[];

  if ((opportunities['undervalued'] as List).isNotEmpty) {
    widgets.add(_buildOpportunitySection(
      'Selling Opportunities',
      'Cards you could sell for profit',
      opportunities['undervalued'] as List,
      Colors.green,
      Icons.trending_up,
    ));
    widgets.add(const SizedBox(height: 16));
  }

  if ((opportunities['overvalued'] as List).isNotEmpty) {
    widgets.add(_buildOpportunitySection(
      'Buying Opportunities',
      'Cards you might want to wait to buy',
      opportunities['overvalued'] as List,
      Colors.orange,
      Icons.trending_down,
    ));
  }

  return widgets;
}

  Widget _buildOpportunitySection(
    String title,
    String subtitle,
    List<dynamic> opportunities,
    Color color,
    IconData icon,
  ) {
    final currencyProvider = context.read<CurrencyProvider>();
    final typedOpportunities = opportunities.cast<Map<String, dynamic>>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title == 'Selling Opportunities' 
                        ? 'Good Time to Sell'
                        : 'Price Drop Alert',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title == 'Selling Opportunities'
                        ? 'Market price is higher than your purchase price'
                        : 'Market price is lower than current listings',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...typedOpportunities.take(3).map((card) {
          final currentPrice = (card['currentPrice'] as num).toDouble();
          final marketPrice = (card['marketPrice'] as num).toDouble();
          final percentDiff = (card['percentDiff'] as num).toDouble();
          final priceDiff = marketPrice - currentPrice;
          final profit = priceDiff.abs();
          
          return InkWell(
            onTap: () => _showMarketDetails(card),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            children: [
                              TextSpan(
                                text: title == 'Selling Opportunities' 
                                    ? 'Your cost: ${currencyProvider.formatValue(currentPrice)}'
                                    : 'Current price: ${currencyProvider.formatValue(currentPrice)}',
                              ),
                              const TextSpan(text: ' • '),
                              TextSpan(
                                text: title == 'Selling Opportunities'
                                    ? 'Can sell for: ${currencyProvider.formatValue(marketPrice)}'
                                    : 'Market price: ${currencyProvider.formatValue(marketPrice)}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      title == 'Selling Opportunities'
                          ? '+${currencyProvider.formatValue(profit)} profit'
                          : '-${currencyProvider.formatValue(profit)} cheaper',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showMarketDetails(Map<String, dynamic> card) {
    final currencyProvider = context.read<CurrencyProvider>();
    final currentPrice = (card['currentPrice'] as num).toDouble();
    final marketPrice = (card['marketPrice'] as num).toDouble();
    final priceDiff = marketPrice - currentPrice;
    final isSellingOpportunity = priceDiff > 0;
    final priceRange = card['priceRange'] as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isSellingOpportunity ? Colors.green : Colors.orange,
                    isSellingOpportunity 
                        ? Colors.green.withOpacity(0.7) 
                        : Colors.orange.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['name'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSellingOpportunity 
                        ? 'Potential profit opportunity!'
                        : 'Price is above market average',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMarketDetailRow(
                    'Your Collection Price',
                    currencyProvider.formatValue(currentPrice),
                    subtitle: 'Price when added to collection',
                  ),
                  _buildMarketDetailRow(
                    'Current Market Price',
                    currencyProvider.formatValue(marketPrice),
                    subtitle: 'Based on recent listings',
                  ),
                  _buildMarketDetailRow(
                    isSellingOpportunity ? 'Potential Profit' : 'Price Difference',
                    currencyProvider.formatValue(priceDiff.abs()),
                    isHighlight: true,
                    color: isSellingOpportunity ? Colors.green : Colors.orange,
                    subtitle: '${card['recentSales']} recent sales found',
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRangeInfo(priceRange, currencyProvider),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isSellingOpportunity ? Colors.green : Colors.blue,
                            isSellingOpportunity 
                                ? Colors.green.shade700 
                                : Colors.blue.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final url = 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(card['name'] as String)} pokemon card';
                          await _launchUrl(url);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.open_in_new, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isSellingOpportunity 
                                  ? 'Check Current Listings' 
                                  : 'View on eBay',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildMarketDetailRow(String label, String value, {
    bool isHighlight = false,
    Color? color,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : null,
              color: color ?? (isHighlight ? Theme.of(context).colorScheme.primary : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeInfo(Map<String, dynamic> priceRange, CurrencyProvider currencyProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Price Range',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPricePoint('Low', priceRange['min'] as double, currencyProvider),
              _buildPricePoint('Median', priceRange['median'] as double, currencyProvider),
              _buildPricePoint('High', priceRange['max'] as double, currencyProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricePoint(String label, double price, CurrencyProvider currencyProvider) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyProvider.formatValue(price),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    final localizations = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: StandardAppBar.createIfSignedIn(
        context,
        transparent: true,
        elevation: 0,
        actions: isSignedIn ? _buildAppBarActions() : null,
        onLeadingPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const AppDrawer(),
      body: Container(
        color: isDarkMode 
            ? Theme.of(context).colorScheme.background 
            : const Color(0xFFEEF6FF),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(isDarkMode ? 0.9 : 0.8),
                      Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            SafeArea(
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

                        LoggingService.debug('AnalyticsScreen: cards.length = ${cards.length}');

                        return CustomScrollView(
                          key: const ValueKey('analytics_scroll_view'),
                          controller: AnalyticsScreen._scrollController,
                          slivers: [
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 24),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildValueSummary(cards),
                                    const SizedBox(height: 12),
                                    Provider<List<TcgCard>>.value(
                                      value: cards,
                                      child: const PortfolioValueChart(
                                        useFullWidth: true,
                                        chartPadding: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildMarketInsightsCard(cards),
                                    const SizedBox(height: 16),
                                    _buildTopMovers(cards),
                                    const SizedBox(height: 16),
                                    _buildTopCardsCard(cards),
                                    const SizedBox(height: 16),
                                    _buildSetDistribution(cards),
                                    const SizedBox(height: 16),
                                    _buildPriceRangeDistribution(cards),
                                    const SizedBox(height: 16),
                                    AcquisitionTimelineChart(cards: cards),
                                    const SizedBox(height: 16),
                                    RarityDistributionChart(cards: cards),
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      StreamBuilder<List<TcgCard>>(
        stream: Provider.of<StorageService>(context).watchCards(),
        builder: (context, snapshot) {
          final hasCards = snapshot.hasData && (snapshot.data?.isNotEmpty ?? false);
          
          if (!hasCards) return const SizedBox.shrink();
          
          return Padding(
            padding: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
            child: PriceUpdateButton(
              isLoading: _isRefreshing,
              lastUpdateTime: _lastUpdateTime,
              onPressed: _isRefreshing ? null : _refreshPrices,
            ),
          );
        }
      ),
    ];
  }

  Widget _buildValueSummary(List<TcgCard> cards) {
  final currencyProvider = context.watch<CurrencyProvider>();
  final storageService = Provider.of<StorageService>(context, listen: false);
  final points = ChartService.getPortfolioHistory(storageService, cards);
  
  double dayChange = 0;
  if (points.length >= 2) {
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final oldPoint = points.firstWhere(
      (p) => p.$1.isAfter(oneDayAgo),
      orElse: () => points.first,
    );
    
    final latestValue = points.last.$2;
    final oldValue = oldPoint.$2;
    if (oldValue > 0) {
      dayChange = ((latestValue - oldValue) / oldValue) * 100;
    }
  }

  final valueInEur = points.last.$2;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade700.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: valueInEur),
                  builder: (context, value, child) => Text(
                    currencyProvider.formatValue(value),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.style_outlined,
                            size: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${cards.length} Cards',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dayChange >= 0 
                  ? Colors.white.withOpacity(0.15)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dayChange >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${dayChange >= 0 ? '+' : ''}${dayChange.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '24h',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
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

  Widget _buildChangeIndicator(double change, double? changeAmount, CurrencyProvider currencyProvider) {
  final isPositive = change >= 0;
  final amountText = changeAmount != null ? '${isPositive ? '+' : ''}${currencyProvider.formatValue(changeAmount)}' : '';
  
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
    child: Column(
      children: [
        // Percentage change
        Row(
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
        // Monetary change (if available)
        if (changeAmount != null) 
          Text(
            amountText,
            style: TextStyle(
              fontSize: 11,
              color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
              fontWeight: FontWeight.w500,
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

  Widget _buildCardImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox(
        // Default placeholder for missing images
        child: Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    
    return Image.network(
      imageUrl,
      height: 40,
      width: 28,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 28,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.broken_image_outlined,
            size: 20,
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
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  margin: const EdgeInsets.symmetric(vertical: 16),
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
      ),
    );
  }

  double _calculateNiceInterval(double range) {
    final magnitude = range.toString().split('.')[0].length;
    final powerOf10 = math.pow(10, magnitude - 1).toDouble();
    
    final candidates = [1.0, 2.0, 2.5, 5.0, 10.0];
    for (final multiplier in candidates) {
      final interval = multiplier * powerOf10;
      if (range / interval <= 6) {
        return interval;
      }
    }
    
    return powerOf10 * 10;
  }

  void _onScroll() {
  }
}

class FullWidthAnalyticsChart extends StatelessWidget {
  const FullWidthAnalyticsChart({Key? key}) : super(key: key);

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

String _formatPricePeriod(dynamic period) {
  if (period == null) return '';
  
  if (period is MapEntry) {
    return period.key.toString();
  }
  
  if (period is Map && period.isNotEmpty) {
    final entry = period.entries.first;
    return entry.key.toString();
  }
  
  if (period is String) return period;
  
  return 'Last 24h';
}

