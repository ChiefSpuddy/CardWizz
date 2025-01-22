import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../providers/app_state.dart';
import '../models/tcg_card.dart';
import '../screens/card_details_screen.dart';
import '../widgets/sign_in_button.dart';  // Remove sign_in_prompt import

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
                reservedSize: 50,
                interval: maxY > 100 ? maxY / 5 : maxY / 4,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value >= 1000
                        ? '€${(value/1000).toStringAsFixed(1)}k'
                        : '€${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          minY: 0, // Force minimum to zero
          maxY: maxY + padding,
          clipData: FlClipData.all(), // Add clipping
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(valuePoints.length, (i) {
                return FlSpot(i.toDouble(), valuePoints[i]);
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSignedIn = appState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: !isSignedIn 
        ? const SignInButton(
            message: 'Sign in to track your collection value and stats',
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
              final cards = snapshot.data ?? [];
              final reversedCards = cards.reversed.toList();  // Add this line
              
              return ListView(
                children: [
                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                            '€${cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0)).toStringAsFixed(2)}',
                            Icons.euro,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price Trend Chart
                  if (cards.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
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

                  // Recent Cards
                  if (cards.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
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
                                        '€${card.price!.toStringAsFixed(2)}',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
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
