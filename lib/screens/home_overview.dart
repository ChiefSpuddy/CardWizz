import 'dart:math' as math show pow;
import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../services/tcg_api_service.dart';
import '../providers/app_state.dart';
import '../models/tcg_card.dart';
import '../screens/card_details_screen.dart';
import '../providers/currency_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/sign_in_view.dart';
import '../screens/home_screen.dart';
import '../utils/hero_tags.dart';
import '../utils/cache_manager.dart';
import '../services/chart_service.dart';
import '../widgets/empty_collection_view.dart';
import '../widgets/portfolio_value_chart.dart';
import '../widgets/standard_app_bar.dart'; // Add this import

class HomeOverview extends StatefulWidget {
  const HomeOverview({super.key});

  @override
  State<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<HomeOverview> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  // Add these variables at the top of the class
  static const int cardsPerPage = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  final ScrollController _latestSetScrollController = ScrollController();

  // Add this cache variable
  static const String LATEST_SET_CACHE_KEY = 'latest_set_cards';
  final _cacheManager = CustomCacheManager();  // Update the instance name

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);
    
    _latestSetScrollController.addListener(_onLatestSetScroll);
  }

  @override
  void dispose() {
    _latestSetScrollController.removeListener(_onLatestSetScroll);
    _latestSetScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onLatestSetScroll() {
    if (_latestSetScrollController.position.pixels >
        _latestSetScrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
      _loadMoreLatestSetCards();
    }
  }

  Future<void> _loadMoreLatestSetCards() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPageData = await Provider.of<TcgApiService>(context, listen: false)
          .searchSet('sv8pt5', page: _currentPage + 1, pageSize: cardsPerPage);
      
      final currentData = await _cacheManager.get('${LATEST_SET_CACHE_KEY}_sv8pt5');
      if (currentData != null) {
        final List currentCards = currentData['data'];
        final List newCards = nextPageData['data'];
        
        // Merge and cache the new data
        final mergedData = {
          ...nextPageData,
          'data': [...currentCards, ...newCards],
        };
        
        await _cacheManager.set(
          '${LATEST_SET_CACHE_KEY}_sv8pt5',
          mergedData,
          const Duration(hours: 1),
        );
        
        setState(() {
          _currentPage++;
        });
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildPriceChart(List<TcgCard> cards) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    // Get timeline points from service
    final points = ChartService.getPortfolioHistory(storageService, cards);
    
    // Early returns for empty states...
    if (points.length < 2) return Card(
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

    // Calculate current total value
    final currentTotalValue = ChartService.calculateTotalValue(cards);

    // Extract values and calculate ranges
    final values = points.map((p) => p.$2).toList();
    final maxValue = values.reduce(max);
    final minValue = values.reduce(min);
    
    // Increase the chart padding for better visualization
    final chartPadding = (maxValue - minValue) * 0.15;
    
    // Calculate nice intervals for the chart
    final interval = _calculateNiceInterval(maxValue - minValue);
    final adjustedMin = (minValue / interval).floor() * interval;
    final adjustedMax = ((maxValue / interval).ceil()) * interval;

    // Convert to spots for the chart
    final spots = points.map((point) {
      return FlSpot(
        point.$1.millisecondsSinceEpoch.toDouble(),
        point.$2,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Collection Value Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              currencyProvider.formatValue(maxValue),
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 24), // Add left padding and increase right padding
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Theme.of(context).colorScheme.surface,
                    tooltipRoundedRadius: 8,
                    fitInsideHorizontally: true,  // Add this line
                    fitInsideVertically: true,    // Add this line
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
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: interval, // Use calculated interval
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
                      interval: interval,  // Use calculated interval
                      reservedSize: 46,
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
                minY: adjustedMin,
                maxY: adjustedMax,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,  // Use spots instead of chartSpots
                    isCurved: true,
                    curveSmoothness: 0.8, // Increased from 0.3 to 0.8 for more curve
                    preventCurveOverShooting: false, // Changed to false to allow smoother curves
                    color: Colors.green.shade600,
                    barWidth: 3, // Slightly increased for better visibility
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 6, // Increased from 4
                          color: Colors.white,
                          strokeWidth: 2.5, // Increased from 2
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
                          Colors.green.shade600.withOpacity(0.3), // Slightly increased opacity
                          Colors.green.shade600.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateNiceInterval(double range) {
    final magnitude = range.toString().split('.')[0].length;
    final powerOf10 = math.pow(10, magnitude - 1).toDouble();
    
    final candidates = [1.0, 2.0, 2.5, 5.0, 10.0];
    for (final multiplier in candidates) {
      final interval = multiplier * powerOf10;
      if (range / interval <= 6) return interval;
    }
    
    return powerOf10 * 10;
  }

  Widget _buildTopCards(List<TcgCard> cards) {
    final localizations = AppLocalizations.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();
    final sortedCards = List<TcgCard>.from(cards)
      ..sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    final topCards = sortedCards.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                localizations.translate('mostValuable'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _navigateToCollection,
                child: Text(localizations.translate('viewAll')),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: topCards.isEmpty
              ? _buildCardLoadingAnimation()  // Replace shimmer
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: topCards.length,
                  itemBuilder: (context, index) {
                    final card = topCards[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardDetailsScreen(
                            card: card,
                            heroContext: 'home_topcard_${card.id}', // Update this line
                          ),
                        ),
                      ),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 4), // Changed from 8 to 4
                        child: Column(
                          children: [
                            Expanded(
                              child: Hero(
                                tag: 'home_topcard_${card.id}', // Update this line
                                child: Image.network(
                                  card.imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            if (card.price != null)
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  currencyProvider.formatValue(card.price!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: topCards.isEmpty
                ? _buildTableLoadingAnimation()  // Replace shimmer
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              localizations.translate('cardName'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              localizations.translate('value'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      ...topCards.take(5).map((card) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                card.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                currencyProvider.formatValue(card.price ?? 0),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade600,  // Modern green color
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestSetCards(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    final localizations = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('latestSet'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Prismatic Evolutions',  // Updated set name
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: FutureBuilder(
            // Update the search query to use sv8pt5 instead of sv8
            future: _getLatestSetCards(context, setId: 'sv8pt5'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _buildCardLoadingAnimation();
              }
              final cards = (snapshot.data?['data'] as List?) ?? [];
              
              // Sort by set number in descending order (highest to lowest)
              cards.sort((a, b) {
                final numA = int.tryParse(a['number'] ?? '') ?? 0;
                final numB = int.tryParse(b['number'] ?? '') ?? 0;
                return numB.compareTo(numA); // Reverse order for highest first
              });

              return Stack(
                children: [
                  ListView.builder(
                    controller: _latestSetScrollController,  // Add the scroll controller
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: cards.length + 1,  // Add 1 for loading indicator
                    itemBuilder: (context, index) {
                      if (index == cards.length) {
                        return _isLoadingMore
                            ? Container(
                                width: 100,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              )
                            : const SizedBox.shrink();
                      }

                      final card = cards[index];
                      // Convert API card data to TcgCard model
                      final tcgCard = TcgCard(
                        id: card['id'],
                        name: card['name'],
                        number: card['number'],
                        imageUrl: card['images']['small'],
                        largeImageUrl: card['images']['large'],
                        rarity: card['rarity'],
                        set: card['set'] != null ? TcgSet(
                          id: card['set']['id'] ?? '',
                          name: card['set']['name'] ?? 'Unknown Set',
                          // Remove required parameters that might be null
                        ) : TcgSet(
                          id: '',
                          name: 'Unknown Set',
                        ),
                        price: card['cardmarket']?['prices']?['averageSellPrice'],
                      );
                      
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardDetailsScreen(
                              card: tcgCard,
                              heroContext: 'home_top',
                            ),
                          ),
                        ),
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 8), // Changed from 4 to 8
                          child: Column(
                            children: [
                              Expanded(
                                child: Hero(
                                  tag: 'latest_${tcgCard.id}',
                                  child: Image.network(
                                    tcgCard.imageUrl,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              if (tcgCard.price != null)
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(
                                    currencyProvider.formatValue(tcgCard.price!),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Update the method to accept setId parameter
  Future<Map<String, dynamic>> _getLatestSetCards(BuildContext context, {String setId = 'sv8pt5'}) async {
    try {
      // Update cache key to include setId
      final cacheKey = '${LATEST_SET_CACHE_KEY}_$setId';
      
      // Try to get cached data first
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      // If no cached data, fetch from API
      final data = await Provider.of<TcgApiService>(context, listen: false).searchSet(setId, page: _currentPage, pageSize: cardsPerPage);
      
      // Cache the response for 1 hour
      await _cacheManager.set(cacheKey, data, const Duration(hours: 1));
      
      return data;
    } catch (e) {
      print('Error loading latest set cards: $e');
      rethrow;
    }
  }

  Widget _buildEmptyState() {
    // Wrap in a Scaffold with no appBar to properly override parent Scaffold
    return Scaffold(
      // Explicitly set appBar to null to hide it
      appBar: null,
      // Make background transparent so parent's background shows through
      backgroundColor: Colors.transparent,
      body: const EmptyCollectionView(
        title: 'Welcome to CardWizz',
        message: 'Start building your collection by adding cards',
        buttonText: 'Add Your First Card',
        icon: Icons.add_circle_outline,
        showHeader: false, // Hide the redundant header
        showAppBar: false, // Explicitly set to false to hide app bar
      ),
    );
  }

  void _navigateToCollection() {
    if (!mounted) return;
    // Use pushNamed and routes instead of pushing MaterialPageRoute directly
    final HomeScreenState? homeState = context.findAncestorStateOfType<HomeScreenState>();
    if (homeState != null) {
      homeState.setSelectedIndex(1); // Index 1 is the Collections tab
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;

    // If not signed in, return the SignInView without showing navigation bar
    if (!isSignedIn) {
      // Use the same Scaffold wrapper approach for SignInView
      return Scaffold(
        appBar: null,
        backgroundColor: Colors.transparent,
        body: const SignInView(showNavigationBar: false, showAppBar: false),
      );
    }

    // User is signed in - do NOT wrap with another Scaffold since the parent HomeScreen already provides one
    final user = appState.currentUser;
    final localizations = AppLocalizations.of(context);

    return StreamBuilder<List<TcgCard>>(
      stream: Provider.of<StorageService>(context).watchCards(),
      initialData: const [],
      builder: (context, snapshot) {
        final currencyProvider = context.watch<CurrencyProvider>();
        final cards = snapshot.data ?? [];
        
        final totalValueEur = cards.fold<double>(
          0, 
          (sum, card) => sum + (card.price ?? 0)
        );
        
        final displayValue = currencyProvider.formatValue(totalValueEur);
        final reversedCards = cards.reversed.toList();
        
        if (cards.isEmpty) {
          return _buildEmptyState();
        }

        return Stack(
          children: [
            // Background animation
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Lottie.asset( 
                  'assets/animations/background.json',
                  fit: BoxFit.cover,
                  repeat: true,
                  frameRate: FrameRate(30),
                  controller: _animationController,
                ),
              ),
            ),
            
            // Main content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message - moved from AppBar to a Padding
                  if (user?.username != null) 
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.titleMedium,
                          children: [
                            TextSpan(
                              text: '${localizations.translate('welcome')} ',
                            ),
                            TextSpan(
                              text: '@${user?.username ?? 'Guest'}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Total Cards',
                            cards.length.toString(),
                            Icons.style,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Collection Value',
                            displayValue,
                            Icons.currency_exchange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price Trend Chart
                  if (cards.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced padding from 16 to 8
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Provider<List<TcgCard>>.value(
                            value: cards,
                            child: const PortfolioValueChart(
                              useFullWidth: true, // Set to true to use full width
                              chartPadding: 16, // Add padding for better appearance
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Most Valuable Cards
                  if (cards.isNotEmpty) ...[
                    _buildTopCards(cards),
                    const SizedBox(height: 8),
                    _buildLatestSetCards(context),
                    const SizedBox(height: 8),
                  ],

                  // Recent Cards
                  if (cards.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            localizations.translate('recentAdditions'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _navigateToCollection,
                            child: Text(localizations.translate('viewAll')),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: reversedCards.length.clamp(0, 10),
                        itemBuilder: (context, index) {
                          final card = reversedCards[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CardDetailsScreen(
                                  card: card,
                                  heroContext: 'home_recent',
                                ),
                              ),
                            ),
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 4),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: HeroTags.cardImage(card.id, context: 'home_recent'),
                                      child: Image.network(
                                        card.imageUrl,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  if (card.price != null)
                                    Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        currencyProvider.formatValue(card.price!),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final localizations = AppLocalizations.of(context);
    final translationKey = title == 'Total Cards' ? 'totalCards' : 
                          title == 'Collection Value' ? 'portfolioValue' : 
                          title.toLowerCase().replaceAll(' ', '_');
    
    // Remove animation opacity to keep cards always visible
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              title.toLowerCase().contains('value') 
                  ? Icons.currency_exchange
                  : icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate(translationKey),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
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
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  // Add these new methods for shimmer loading effects
  Widget _buildCardLoadingAnimation() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: const EdgeInsets.only(right: 8),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 14,
                width: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableLoadingAnimation() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildLoadingBar(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLoadingBar(),
            ),
          ],
        ),
        const Divider(height: 16),
        ...List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildLoadingBar(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLoadingBar(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingBar() {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
