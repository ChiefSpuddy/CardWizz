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
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            ),
            checkToShowHorizontalLine: (value) => value >= 0, // Only show lines above 0
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: max(1, valuePoints.length / 6).toDouble(),
                getTitlesWidget: (value, _) {
                  if (value.toInt() >= cards.length) return const SizedBox.shrink();
                  final date = DateTime.now().subtract(Duration(days: cards.length - 1 - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                interval: maxY > 100 ? maxY / 5 : maxY / 4,
                getTitlesWidget: (value, _) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      currencyProvider.formatChartValue(value),  // Use chart-specific formatting
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          minY: 0, // Force minimum to zero
          maxY: maxY + padding,
          clipData: FlClipData.all(), // Add clipping
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(valuePoints.length, (i) {
                // Round to 2 decimal places to avoid floating point precision issues
                final roundedValue = (valuePoints[i] * 100).round() / 100;
                return FlSpot(i.toDouble(), roundedValue);
              }),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCards(List<TcgCard> cards) {
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
              const Text(
                'Your Most Valuable Cards',
                style: TextStyle(
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
                child: const Text('View All'),
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
                        'Card Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Value',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Latest Set',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Surging Sparks',
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
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            card['images']['small'],
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (card['cardmarket']?['prices']?['averageSellPrice'] != null)
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              '€${card['cardmarket']['prices']['averageSellPrice'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('overview')),  // Add translation
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: !isSignedIn 
        ? SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SignInButton(
                  message: localizations.translate('signInToTrack'),  // Add translation
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    localizations.translate('popularCards'),  // Add translation
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: FutureBuilder(
                    future: Provider.of<TcgApiService>(context).searchCards('', 
                      customQuery: TcgApiService.popularSearchQueries['Charizard']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final cards = (snapshot.data?['data'] as List?) ?? [];
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cards.length.clamp(0, 10),
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 8),
                            child: Image.network(
                              card['images']['small'],
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Latest Sets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: FutureBuilder(
                    future: Provider.of<TcgApiService>(context).searchCards('', 
                      customQuery: TcgApiService.setSearchQueries['Paldea Evolved']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final cards = (snapshot.data?['data'] as List?) ?? [];
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cards.length.clamp(0, 10),
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 8),
                            child: Image.network(
                              card['images']['small'],
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),  // Reduced padding
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Collection Value Trend',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPriceChart(cards),
                            ],
                          ),
                        ),
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
                          const Text(
                            'Recent Additions',
                            style: TextStyle(
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
                            child: const Text('View All'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Replace the euro icon with a more generic currency icon
            Icon(
              title.toLowerCase().contains('value') 
                  ? Icons.currency_exchange  // Use currency_exchange for value cards
                  : icon,
              size: 32
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate(title),  // Add translation
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
