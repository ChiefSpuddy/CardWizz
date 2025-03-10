import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Simple replacement for the removed CardBattleStats class
class CardBattleStats {
  final double attackPower;
  final double defensePower;
  final double specialPower;
  final double speed;
  
  CardBattleStats({
    required this.attackPower,
    required this.defensePower,
    required this.specialPower,
    required this.speed,
  });
}

class CardStatsRadar extends StatelessWidget {
  final CardBattleStats stats;
  final Color color;
  final bool showLabels;
  final double size;
  
  const CardStatsRadar({
    Key? key,
    required this.stats,
    this.color = Colors.blue,
    this.showLabels = true,
    this.size = 1.0, // Scale factor
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Normalize stats to 0-1 range for radar chart
    final maxStatValue = 50.0; // Normalization factor
    final attackValue = (stats.attackPower / maxStatValue).clamp(0.0, 1.0);
    final defenseValue = (stats.defensePower / maxStatValue).clamp(0.0, 1.0);
    final specialValue = (stats.specialPower / maxStatValue).clamp(0.0, 1.0);
    final speedValue = (stats.speed / maxStatValue).clamp(0.0, 1.0);
    
    return SizedBox(
      width: 220 * size,
      height: 220 * size,
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: [
                RadarEntry(value: attackValue),
                RadarEntry(value: defenseValue),
                RadarEntry(value: specialValue),
                RadarEntry(value: speedValue),
              ],
              fillColor: color.withOpacity(0.2),
              borderColor: color,
              borderWidth: 2,
              entryRadius: 2,
            ),
          ],
          radarBorderData: const BorderSide(color: Colors.transparent),
          radarBackgroundColor: Colors.transparent,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          tickBorderData: const BorderSide(color: Colors.white24, width: 1),
          gridBorderData: const BorderSide(color: Colors.white24, width: 1),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 12 * size,
            fontWeight: FontWeight.bold,
          ),
          getTitle: (index) {
            if (!showLabels) return '';
            switch (index) {
              case 0:
                return 'ATK';
              case 1: 
                return 'DEF';
              case 2:
                return 'SP';
              case 3:
                return 'SPD';
              default:
                return '';
            }
          },
          titlePositionPercentageOffset: 0.2,
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
