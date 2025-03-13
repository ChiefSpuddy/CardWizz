import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import '../models/tcg_card.dart';

class RarityDistributionChart extends StatelessWidget {
  final List<TcgCard> cards;

  const RarityDistributionChart({
    Key? key,
    required this.cards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate rarity distribution
    final rarityMap = _getRarityDistribution();
    
    // If there's no rarity data, show empty state
    if (rarityMap.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Create sorted list of rarity types
    final rarityData = rarityMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    // Color map for common rarities
    final rarityColors = {
      'Common': Colors.grey.shade500,
      'Uncommon': Colors.green.shade500,
      'Rare': Colors.blue.shade500,
      'Rare Holo': Colors.purple.shade500,
      'Ultra Rare': Colors.orange.shade500,
      'Secret Rare': Colors.red.shade500,
      'Rare Ultra': Colors.pink.shade500,
      'Promo': Colors.amber.shade500,
      'Rainbow Rare': Colors.deepPurple.shade500,
      'Hyper Rare': Colors.deepOrange.shade500,
      'Amazing Rare': Colors.indigo.shade500,
    };
    
    // Calculate total for percentages
    final total = rarityMap.values.fold<int>(0, (sum, val) => sum + val);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rarity Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Breakdown of card rarities in your collection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.5,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  sections: rarityData.take(8).mapIndexed((index, entry) {
                    final rarity = entry.key;
                    final count = entry.value;
                    final percent = (count / total * 100).toStringAsFixed(1);
                    
                    return PieChartSectionData(
                      value: count.toDouble(),
                      title: '$percent%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      color: rarityColors[rarity] ?? 
                        Color.fromARGB(
                          255,
                          150 + (index * 20) % 105,
                          100 + (index * 30) % 155,
                          200 - (index * 25) % 100,
                        ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: rarityData.take(8).mapIndexed((index, entry) {
                final rarity = entry.key;
                final count = entry.value;
                final color = rarityColors[rarity] ?? 
                  Color.fromARGB(
                    255,
                    150 + (index * 20) % 105,
                    100 + (index * 30) % 155,
                    200 - (index * 25) % 100,
                  );
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rarity,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$count cards',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (rarityData.length > 8) ...[
              Center(
                child: Text(
                  '+ ${rarityData.length - 8} more rarity types',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildRarityInsights(context, rarityData, total),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityInsights(
    BuildContext context, 
    List<MapEntry<String, int>> rarityData,
    int total,
  ) {
    final mostCommonRarity = rarityData.first;
    final mostCommonPercent = (mostCommonRarity.value / total * 100).toStringAsFixed(1);
    
    final rarityCount = rarityData.length;
    final rareCardCount = rarityData
      .where((e) => !['Common', 'Uncommon', 'Energy'].contains(e.key))
      .fold<int>(0, (sum, e) => sum + e.value);
    final rareCardPercent = (rareCardCount / total * 100).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.diamond_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Rarity Insights',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Most common: ${mostCommonRarity.key} ($mostCommonPercent%)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Rare cards: $rareCardCount ($rareCardPercent% of collection)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Rarity types: $rarityCount different rarities',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Rarity Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.diamond_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No rarity data available',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add cards with rarity information to see distribution',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getRarityDistribution() {
    final rarityMap = <String, int>{};
    
    for (final card in cards) {
      if (card.rarity != null && card.rarity!.isNotEmpty) {
        final rarity = card.rarity!;
        rarityMap[rarity] = (rarityMap[rarity] ?? 0) + 1;
      }
    }
    
    return rarityMap;
  }
}
