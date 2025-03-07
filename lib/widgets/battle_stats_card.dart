import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart'; // Add this import for charts
import 'dart:ui'; // Add this import for ImageFilter

class BattleStatsCard extends StatelessWidget {
  final int wins;
  final int losses;
  final int draws;
  
  const BattleStatsCard({
    super.key,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  @override
  Widget build(BuildContext context) {
    final total = max(1, wins + losses + draws); // Avoid division by zero
    final winRate = wins / total;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and win rate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events_outlined,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Combat Stats',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getWinRateColor(winRate),
                          _getWinRateColor(winRate).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(winRate * 100).toStringAsFixed(1)}% Win',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Stats in modern layout
              Row(
                children: [
                  // Stat metrics
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBadge('Wins', wins, Colors.green),
                        _buildStatBadge('Losses', losses, Colors.red),
                        _buildStatBadge('Draws', draws, Colors.amber),
                      ],
                    ),
                  ),
                  
                  // Add pie chart for win/loss ratio
                  if (total > 1) ...[
                    const SizedBox(width: 20),
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  color: Colors.green,
                                  value: wins.toDouble(),
                                  radius: 25,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.red,
                                  value: losses.toDouble(),
                                  radius: 25,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.amber,
                                  value: draws.toDouble(),
                                  radius: 25,
                                  showTitle: false,
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 20,
                              startDegreeOffset: -90,
                            ),
                          ),
                          Center(
                            child: Text(
                              '$total',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatBadge(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Color _getWinRateColor(double winRate) {
    if (winRate >= 0.7) return Colors.green;
    if (winRate >= 0.5) return Colors.lime;
    if (winRate >= 0.3) return Colors.orange;
    return Colors.red;
  }
}
