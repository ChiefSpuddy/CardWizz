import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../services/tcg_api_service.dart';  // Add this import
import '../providers/app_state.dart';
import '../models/tcg_card.dart';
import '../screens/card_details_screen.dart';
import '../widgets/sign_in_button.dart';  // Remove sign_in_prompt import
import '../providers/currency_provider.dart';  // Add this import
import '../l10n/app_localizations.dart';  // Add this import
import '../widgets/sign_in_view.dart';  // Add this import
import '../screens/home_screen.dart';  // Add this import at the top with other imports

class HomeOverview extends StatefulWidget {
  const HomeOverview({super.key});

  @override
  State<HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<HomeOverview> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildPriceChart(List<TcgCard> cards) {
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

    // Calculate cumulative value points
    final sortedCards = List<TcgCard>.from(cards)
      ..sort((a, b) => a.price?.compareTo(b.price ?? 0) ?? 0);
    
    double cumulativeValue = 0;
    final valuePoints = sortedCards
        .where((card) => card.price != null)
        .map((card) {
          cumulativeValue += card.price!;
          return cumulativeValue;
        })
        .toList();
    
    if (valuePoints.isEmpty) return const SizedBox.shrink();

    final maxY = valuePoints.last;  // Use total value as max
    final minY = 0.0;  // Start from zero
    final padding = maxY * 0.1;  // 10% padding

    // Calculate interval based on the range
    final interval = valuePoints.length == 1 
        ? maxY / 2  // Use half of max value for single point
        : maxY / 4;  // Split into quarters for multiple points

    return SizedBox(
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
                  if (value.toInt() >= cards.length) return const SizedBox.shrink();
                  final date = DateTime.now().subtract(Duration(days: cards.length - 1 - value.toInt()));
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
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Theme.of(context).cardColor,
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot spot) {
                  return LineTooltipItem(
                    currencyProvider.formatValue(spot.y),
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList();
              },
              fitInsideHorizontally: true,
              fitInsideVertically: true,
            ),
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> indicators) {
              return indicators.map((int index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: Colors.green.shade600,
                    strokeWidth: 2,
                    dashArray: [3, 3],
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: Colors.green.shade600,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(valuePoints.length, (i) {
                final value = double.parse(valuePoints[i].toStringAsFixed(2));
                return FlSpot(i.toDouble(), value);
              }),
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
    );
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
                onPressed: () {
                  if (context.mounted) {
                    Navigator.pushNamed(context, '/collection');
                  }
                },
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
            itemCount: topCards.length,
            itemBuilder: (context, index) {
              final card = topCards[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardDetailsScreen(card: card),
                  ),
                ),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Hero(
                          tag: 'topcard_${card.id}',
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
            child: Column(
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
                localizations.translate('surgingSparks'),
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
            future: Provider.of<TcgApiService>(context).searchSet('sv8'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final cards = (snapshot.data?['data'] as List?) ?? [];
              
              // Sort cards by price
              cards.sort((a, b) {
                final priceA = a['cardmarket']?['prices']?['averageSellPrice'] ?? 0.0;
                final priceB = b['cardmarket']?['prices']?['averageSellPrice'] ?? 0.0;
                return (priceB as num).compareTo(priceA as num);
              });

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cards.length.clamp(0, 10),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  // Convert API card data to TcgCard model
                  final tcgCard = TcgCard(
                    id: card['id'],
                    name: card['name'],
                    number: card['number'],
                    imageUrl: card['images']['small'],
                    rarity: card['rarity'],
                    setName: card['set']?['name'],
                    price: card['cardmarket']?['prices']?['averageSellPrice'],
                  );
                  
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailsScreen(card: tcgCard),
                      ),
                    ),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 8),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              localizations.translate('emptyCollection'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('addFirstCard'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                final homeState = context.findAncestorStateOfType<HomeScreenState>();
                if (homeState != null) {
                  homeState.setSelectedIndex(2); // Navigate to scan/add card
                }
              },
              icon: const Icon(Icons.add),
              label: Text(localizations.translate('addCard')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;
    final user = appState.currentUser;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        automaticallyImplyLeading: false,
        title: isSignedIn && user != null ? RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleMedium,
            children: [
              TextSpan(
                text: '${localizations.translate('welcome')} ',
              ),
              TextSpan(
                text: '@${user.username}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ) : null,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: !isSignedIn 
        ? const SignInView()
        : Stack(
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
            // Content
            StreamBuilder<List<TcgCard>>(
              stream: Provider.of<StorageService>(context).watchCards(),
              initialData: const [],
              builder: (context, snapshot) {
                final currencyProvider = context.watch<CurrencyProvider>();
                final cards = snapshot.data ?? [];
                final reversedCards = cards.reversed.toList();  // Add this line
                final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
                
                if (cards.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView(
                  children: [
                    // Summary Cards
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),  // Reduced padding
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
                              currencyProvider.formatValue(totalValue),  // Update this line
                              Icons.currency_exchange,  // This will be overridden by the logic above
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price Trend Chart
                    if (cards.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,  // Changed from start
                          children: [
                            Text(
                              localizations.translate('collectionValueTrend'),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,  // Add this
                            ),
                            const SizedBox(height: 24),  // Adjusted spacing
                            _buildPriceChart(cards),
                          ],
                        ),
                      ),
                    ],

                    // Most Valuable Cards
                    if (cards.isNotEmpty) ...[
                      _buildTopCards(cards),  // Add this line before Recent Additions
                      const SizedBox(height: 8),  // Reduced spacing
                      _buildLatestSetCards(context),  // Add this line
                      const SizedBox(height: 8),  // Reduced spacing
                    ],

                    // Recent Cards
                    if (cards.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),  // Reduced padding
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
                              onPressed: () {
                                if (context.mounted) {
                                  Navigator.pushNamed(context, '/collection');
                                }
                              },
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
                          itemCount: reversedCards.length.clamp(0, 10),  // Use reversedCards
                          itemBuilder: (context, index) {
                            final card = reversedCards[index];  // Use reversedCards
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CardDetailsScreen(card: card),
                                ),
                              ),
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Hero(
                                        tag: 'card_${card.id}',
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
                                          currencyProvider.formatValue(card.price!),  // Update this line
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
                );
              },
            ),
          ],
        ),
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
}
