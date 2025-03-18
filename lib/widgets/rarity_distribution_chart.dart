import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tcg_card.dart';
import 'dart:math' as math;

class RarityDistributionChart extends StatelessWidget {
  final List<TcgCard> cards;
  
  const RarityDistributionChart({
    Key? key,
    required this.cards,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Get distribution data
    final distribution = _calculateRarityDistribution();
    
    // If no data, show empty state
    if (distribution.isEmpty) {
      return const Center(
        child: Text('No rarity data available'),
      );
    }
    
    // Use LayoutBuilder to ensure we respect our parent's constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height after subtracting space for title and legend
        final availableHeight = constraints.maxHeight - 60;
        
        // Make sure we have at least some space for the chart
        final chartHeight = math.max(100, availableHeight);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart title
            Text(
              'Rarity Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Main chart with fixed height - CRITICAL FIX
            // FIX: Convert chartHeight from num to double
            SizedBox(
              height: chartHeight.toDouble(),
              child: PieChart(
                PieChartData(
                  sections: _buildPieSections(distribution),
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      // Optional touch handling
                    },
                  ),
                ),
              ),
            ),
            
            // Legend - using Wrap for flexible layout
            Flexible(
              fit: FlexFit.loose,
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: distribution.entries
                    .map((entry) => _buildLegendItem(
                          context, 
                          entry.key, 
                          entry.value, 
                          _getRarityColor(entry.key),
                          cards.length,
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      }
    );
  }
  
  // Calculate rarity distribution
  Map<String, int> _calculateRarityDistribution() {
    final Map<String, int> distribution = {};
    
    for (final card in cards) {
      final rarity = card.rarity ?? 'Unknown';
      distribution[rarity] = (distribution[rarity] ?? 0) + 1;
    }
    
    // Sort by count (descending)
    final sortedMap = Map.fromEntries(
      distribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
    );
    
    return sortedMap;
  }
  
  // Build pie chart sections
  List<PieChartSectionData> _buildPieSections(Map<String, int> distribution) {
    final total = cards.length;
    final colors = _getColorScheme();
    
    return distribution.entries.map((entry) {
      final percent = entry.value / total * 100;
      final index = distribution.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];
      
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${percent.toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
  
  // Build legend items
  Widget _buildLegendItem(BuildContext context, String rarity, int count, Color color, int total) {
    final percent = count / total * 100;
    
    return SizedBox(
      width: 130,  // Fixed width to ensure consistent layout
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rarity,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count (${percent.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Get color scheme for chart
  List<Color> _getColorScheme() {
    return [
      const Color(0xFF4CAF50),  // Green
      const Color(0xFF2196F3),  // Blue
      const Color(0xFFFFA726),  // Orange
      const Color(0xFFE91E63),  // Pink
      const Color(0xFF9C27B0),  // Purple
      const Color(0xFF00BCD4),  // Cyan
      const Color(0xFFFF5722),  // Deep Orange
      const Color(0xFF607D8B),  // Blue Grey
    ];
  }
  
  // Get color for specific rarity
  Color _getRarityColor(String rarity) {
    final index = _calculateRarityDistribution().keys.toList().indexOf(rarity);
    return _getColorScheme()[index % _getColorScheme().length];
  }
}
