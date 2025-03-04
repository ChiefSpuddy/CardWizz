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
import '../widgets/empty_collection_view.dart';  // Add this import
import '../widgets/portfolio_value_chart.dart';
import 'dart:math' as math;
import '../models/auth_user.dart'; // Add this import for AuthUser
import 'package:flutter/services.dart';
import 'dart:ui';  // Add this for more advanced effects

class HomeOverview extends StatefulWidget {
  const HomeOverview({super.key});

  @override
  State<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<HomeOverview> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _animationController;
  late final AnimationController _backgroundController;
  late final AnimationController _summaryCardsController;
  late final AnimationController _chartController;
  late final AnimationController _topCardsController; 
  late final AnimationController _recentCardsController;
  late final AnimationController _latestSetController;
  late final Animation<double> _pulseAnimation;
  
  // Background animation particles
  final List<_Particle> _particles = [];
  bool _isFirstBuild = true;
  
  // For animated cards
  static const int cardsPerPage = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  final ScrollController _latestSetScrollController = ScrollController();
  static const String LATEST_SET_CACHE_KEY = 'latest_set_cards';
  final _cacheManager = CustomCacheManager();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with different durations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),  // Slower for more noticeable effects
    );
    
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),  // Slower for more subtle background movement
    );
    
    _summaryCardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _topCardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _recentCardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _latestSetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Pulse animation for highlights
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutQuad,
      ),
    );

    // Start animations
    _animationController.forward();
    _animationController.repeat(reverse: true);
    _backgroundController.forward();
    _backgroundController.repeat();

    // Staggered animations with small delays
    Future.delayed(Duration.zero, () {
      if (mounted) _summaryCardsController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _chartController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _topCardsController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _recentCardsController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _latestSetController.forward();
    });
    
    _latestSetScrollController.addListener(_onLatestSetScroll);
    
    // Initialize particles for background effect
    _initializeParticles();
  }
  
  void _initializeParticles() {
    final random = math.Random(42); // Correctly use math.Random
    // Create more particles with varying properties for a more dynamic effect
    for (int i = 0; i < 40; i++) {  // Reduced from 60
      _particles.add(
        _Particle(
          x: random.nextDouble() * 2 - 1, // Position between -1 and 1
          y: random.nextDouble() * 2 - 1,
          size: (1.5 + random.nextDouble() * 3), // Smaller particles
          opacity: 0.05 + random.nextDouble() * 0.2, // Lower opacity
          speed: 0.15 + random.nextDouble() * 0.3, // Slightly slower
          angle: random.nextDouble() * 2 * math.pi, // Use math.pi
        ),
      );
    }
  }

  // Add a new method to update particle colors after build
  void _updateParticleColors() {
    final random = math.Random(42);
    final colorScheme = Theme.of(context).colorScheme;
    
    for (final particle in _particles) {
      // Assign colors from a predefined list including theme colors
      particle.color = [
        Colors.blue.withOpacity(0.3),
        Colors.purple.withOpacity(0.3),
        Colors.pink.withOpacity(0.3),
        colorScheme.primary.withOpacity(0.3),
        colorScheme.secondary.withOpacity(0.3),
      ][random.nextInt(5)];
    }
  }

  // Add didChangeDependencies to update colors when theme changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access Theme here
    _updateParticleColors();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundController.dispose();
    _summaryCardsController.dispose();
    _chartController.dispose();
    _topCardsController.dispose();
    _recentCardsController.dispose();
    _latestSetController.dispose();
    _latestSetScrollController.dispose();
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
    // Return EmptyCollectionView directly for uniform alignment
    return const EmptyCollectionView(
      title: 'Welcome to CardWizz',
      message: 'Start building your collection by adding cards',
      buttonText: 'Add Your First Card',
      icon: Icons.add_circle_outline,
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;
    final user = appState.currentUser;
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        if (isSignedIn)
          _buildAnimatedAppBar(user, localizations, colorScheme),
        if (!isSignedIn && ModalRoute.of(context)?.settings.name == '/')
          const Expanded(child: SignInView())
        else
          Expanded(
            child: Stack(
              children: [
                // Animated Background
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _backgroundController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _BackgroundPainter(
                          animation: _backgroundController.value,
                          particles: _particles,
                          isDark: isDark,
                          primaryColor: colorScheme.primary,
                        ),
                        child: child,
                      );
                    },
                  ),
                ),
                
                // Background subtle gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.background.withOpacity(0.7),
                          colorScheme.background.withOpacity(0.4),
                          colorScheme.background.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Main content with cards stream
                StreamBuilder<List<TcgCard>>(
                  stream: Provider.of<StorageService>(context).watchCards(),
                  builder: (context, snapshot) {
                    print('HomeOverview StreamBuilder: state=${snapshot.connectionState}, hasData=${snapshot.hasData}, dataLength=${snapshot.data?.length ?? 0}');
                    
                    // Always use the latest data
                    final cards = snapshot.data ?? [];
                    
                    // Show empty state if needed
                    if (cards.isEmpty) {
                      return const EmptyCollectionView(
                        title: 'Welcome to CardWizz',
                        message: 'Start building your collection by adding cards',
                        buttonText: 'Add Your First Card',
                        icon: Icons.add_circle_outline,
                      );
                    }
                    
                    // Calculate portfolio value
                    final currencyProvider = context.watch<CurrencyProvider>();
                    final totalValueEur = cards.fold<double>(
                      0, 
                      (sum, card) => sum + (card.price ?? 0)
                    );
                    
                    final displayValue = currencyProvider.formatValue(totalValueEur);
                    final reversedCards = cards.reversed.toList();
                    
                    // Enhanced main content
                    return RefreshIndicator(
                      onRefresh: () async {
                        final storageService = Provider.of<StorageService>(context, listen: false);
                        await storageService.refreshState();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Animated summary cards (Total Cards, Collection Value)
                            _buildAnimatedSummaryCards(
                              context, 
                              cards.length, 
                              displayValue, 
                              localizations
                            ),
                            
                            // Animated portfolio chart
                            _buildAnimatedPortfolioChart(cards),
                            
                            // Animated most valuable cards section
                            _buildAnimatedTopCards(cards, localizations, currencyProvider),
                            
                            // Keep only this instance of Latest Set section - remove any duplicates 
                            _buildLatestSetCards(context),
                            
                            // Animated recent additions
                            _buildAnimatedRecentCards(
                              reversedCards, 
                              localizations, 
                              currencyProvider
                            ),
                            
                            // Bottom spacing
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  // New methods for animated UI components
  
  Widget _buildAnimatedAppBar(dynamic user, AppLocalizations localizations, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _summaryCardsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - _summaryCardsController.value)),
          child: Opacity(
            opacity: _summaryCardsController.value,
            child: Container(
              height: 110, // Increased from 90 to give more vertical space
              decoration: BoxDecoration(
                // Adapt color based on theme
                color: isDark ? colorScheme.surface : Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.2) 
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased vertical padding
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu, 
                          // Use onSurface color for dark mode, primary for light
                          color: isDark ? colorScheme.onSurface : colorScheme.primary, 
                          size: 26,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      const SizedBox(width: 12),
                      if (user?.username != null)
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              // Use onSurface color for dark mode, primary for light
                              color: isDark ? colorScheme.onSurface : colorScheme.primary,
                            ),
                            children: [
                              TextSpan(
                                text: '${localizations.translate('welcome')} ',
                              ),
                              TextSpan(
                                text: '@${user?.username ?? 'Guest'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.refresh, 
                          // Use onSurface color for dark mode, primary for light
                          color: isDark ? colorScheme.onSurface : colorScheme.primary, 
                          size: 26,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final storageService = Provider.of<StorageService>(context, listen: false);
                          storageService.refreshState();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Fix the wobbly animation by removing the pulse animation from summary cards
  Widget _buildAnimatedSummaryCards(
    BuildContext context, 
    int cardCount, 
    String portfolioValue,
    AppLocalizations localizations
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _summaryCardsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _summaryCardsController.value)),
          child: Opacity(
            opacity: _summaryCardsController.value,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Total Cards card - REMOVED the pulse animation
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark 
                                ? colorScheme.surface.withOpacity(0.8)
                                : Colors.white.withOpacity(0.8),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.style_outlined,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  localizations.translate('totalCards'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cardCount.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Collection Value card - REMOVED the pulse animation
                  Expanded(
                    child: Card(
                      elevation: 8,
                      shadowColor: colorScheme.secondary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.secondary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              isDark 
                                ? colorScheme.surface 
                                : Colors.white,
                              isDark 
                                ? colorScheme.surface.withOpacity(0.8) 
                                : Colors.white.withOpacity(0.8),
                              isDark
                                ? Color.lerp(colorScheme.surface, colorScheme.secondary, 0.03) ?? colorScheme.surface
                                : Color.lerp(Colors.white, colorScheme.secondary, 0.01) ?? Colors.white,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade600,
                                    Colors.green.shade400,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              localizations.translate('portfolioValue'),
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              portfolioValue,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade600,
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
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedPortfolioChart(List<TcgCard> cards) {
    return AnimatedBuilder(
      animation: _chartController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _chartController.value)),
          child: Opacity(
            opacity: _chartController.value,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Provider<List<TcgCard>>.value(
                value: cards,
                // Add a Container with a background to prevent background animation from showing through
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // Use a solid or semi-transparent background color based on the theme
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface.withOpacity(0.95)
                        : Theme.of(context).colorScheme.background.withOpacity(0.95),
                    // Optional: add a subtle shadow
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
                    child: const FullWidthPortfolioChart(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedTopCards(
    List<TcgCard> cards, 
    AppLocalizations localizations, 
    CurrencyProvider currencyProvider
  ) {
    final sortedCards = List<TcgCard>.from(cards)
      ..sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    final topCards = sortedCards.take(10).toList();
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: _topCardsController,
      builder: (context, child) {
        // Add a rotation effect along with the translation
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)  // Add perspective
            ..translate(0.0, 40 * (1 - _topCardsController.value))
            ..rotateX((1 - _topCardsController.value) * 0.1),  // Subtle rotation
          alignment: Alignment.center,
          child: Opacity(
            opacity: _topCardsController.value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                // Diamond icon removed from here
                Text(
                  localizations.translate('mostValuable'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _navigateToCollection,
                  icon: Icon(
                    Icons.visibility,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  label: Text(localizations.translate('viewAll')),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: topCards.isEmpty
                ? _buildCardLoadingAnimation()  
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: topCards.length,
                    itemBuilder: (context, index) {
                      final card = topCards[index];
                      // Stagger animation start
                      return AnimatedBuilder(
                        animation: Tween(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(
                            parent: _topCardsController,
                            curve: Interval(
                              0.1 + (index * 0.05),
                              0.5 + (index * 0.05),
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * _topCardsController.value),
                            child: Opacity(
                              opacity: _topCardsController.value,
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CardDetailsScreen(
                                      card: card,
                                      heroContext: 'home_topcard_${card.id}', 
                                    ),
                                  ),
                                ),
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Hero(
                                          tag: 'home_topcard_${card.id}',
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
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: topCards.isEmpty
                  ? _buildTableLoadingAnimation()
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
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                localizations.translate('value'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  currencyProvider.formatValue(card.price ?? 0),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade600,
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
      ),
    );
  }
  
  Widget _buildAnimatedRecentCards(
    List<TcgCard> cards,
    AppLocalizations localizations,
    CurrencyProvider currencyProvider
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final recentCards = cards.take(6).toList();
    
    return AnimatedBuilder(
      animation: _recentCardsController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _recentCardsController.value)),
          child: Opacity(
            opacity: _recentCardsController.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      const Text(
                        "Recently Added", // Direct text instead of translation
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _navigateToCollection,
                        icon: Icon(
                          Icons.visibility,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        label: Text(localizations.translate('viewAll')),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recentCards.length,
                    itemBuilder: (context, index) {
                      final card = recentCards[index];
                      return AnimatedBuilder(
                        animation: Tween(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(
                          CurvedAnimation(
                            parent: _recentCardsController,
                            curve: Interval(
                              0.1 + (index * 0.05),
                              0.5 + (index * 0.05),
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * _recentCardsController.value),
                            child: Opacity(
                              opacity: _recentCardsController.value,
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CardDetailsScreen(
                                      card: card,
                                      heroContext: 'home_recent_${card.id}',
                                    ),
                                  ),
                                ),
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Hero(
                                          tag: 'home_recent_${card.id}',
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
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Loading animations
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
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/card-loading.json',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 20,
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 16),
        for (int i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

// Background painter for animated particles effect
class _BackgroundPainter extends CustomPainter {
  final double animation;
  final List<_Particle> particles;
  final bool isDark;
  final Color primaryColor;

  _BackgroundPainter({
    required this.animation,
    required this.particles,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Create a deterministic random for consistent effects
    
    for (final particle in particles) {
      final x = (particle.x * size.width + animation * particle.speed * size.width * math.cos(particle.angle)) % size.width;
      final y = (particle.y * size.height + animation * particle.speed * size.height * math.sin(particle.angle)) % size.height;

      // Use the particle's color which will be set properly in didChangeDependencies
      final paint = Paint()..color = particle.color;
        
      // Add glow effect to particles
      if (random.nextInt(3) == 0) {
        canvas.drawCircle(Offset(x, y), particle.size * 1.5, 
          Paint()..color = particle.color.withOpacity(0.3)..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0));
      }

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}

// Helper class for background particles
class _Particle {
  final double x;        // Position X (-1 to 1)
  final double y;        // Position Y (-1 to 1)
  final double size;     // Size of particle
  final double opacity;  // Opacity
  final double speed;    // Speed of movement
  final double angle;    // Direction angle
  Color color = Colors.white; // Default color that will be updated later

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.angle,
  });
}

// Add a new creative enhancement: Confetti effect when total value increases
// Add this to the end of the file
class ValueChangeDetector extends StatefulWidget {
  final String value;
  final Widget child;
  
  const ValueChangeDetector({
    Key? key,
    required this.value,
    required this.child,
  }) : super(key: key);
  
  @override
  State<ValueChangeDetector> createState() => _ValueChangeDetectorState();
}

class _ValueChangeDetectorState extends State<ValueChangeDetector> with SingleTickerProviderStateMixin {
  String? previousValue;
  late AnimationController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(ValueChangeDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (previousValue != null && 
        widget.value != previousValue &&
        _parseValue(widget.value) > _parseValue(previousValue!)) {
      _confettiController.forward(from: 0.0);
    }
    
    previousValue = widget.value;
  }
  
  double _parseValue(String value) {
    // Extract numeric value from formatted currency string
    final numericString = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Confetti effect
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, _) {
            if (_confettiController.value == 0) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: MiniConfettiPainter(
                animation: _confettiController.value,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

class MiniConfettiPainter extends CustomPainter {
  final double animation;
  final List<_ConfettiParticle> particles = [];
  
  MiniConfettiPainter({required this.animation}) {
    if (particles.isEmpty) {
      final random = math.Random();
      for (int i = 0; i < 30; i++) {
        particles.add(_ConfettiParticle(
          position: Offset(0.5 + (random.nextDouble() - 0.5) * 0.3, 0.7),
          color: [
            Colors.green,
            Colors.greenAccent,
            Colors.lightGreen,
            Colors.lime,
            Colors.yellow,
          ][random.nextInt(5)],
          radius: 2 + random.nextDouble() * 2,
          velocity: Offset(
            (random.nextDouble() - 0.5) * 2,
            -1 - random.nextDouble() * 2,
          ),
        ));
      }
    }
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final position = Offset(
        particle.position.dx * size.width,
        particle.position.dy * size.height + 
          particle.velocity.dy * animation * size.height * 0.5,
      );
      
      final dx = particle.velocity.dx * animation * size.width * 0.3;
      
      canvas.drawCircle(
        Offset(position.dx + dx, position.dy),
        particle.radius * (1 - animation * 0.7),
        Paint()..color = particle.color.withOpacity(1 - animation),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant MiniConfettiPainter oldDelegate) => true;
}

class _ConfettiParticle {
  final Offset position;
  final Color color;
  final double radius;
  final Offset velocity;
  
  _ConfettiParticle({
    required this.position,
    required this.color,
    required this.radius,
    required this.velocity,
  });
}

class FullWidthPortfolioChart extends StatelessWidget {
  const FullWidthPortfolioChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8), // Add bottom padding to prevent node cut-off
            child: PortfolioValueChart(
              useFullWidth: true, 
              chartPadding: 16, // Add chart padding to ensure nodes stay within bounds
            ),
          ),
        );
      },
    );
  }
}