import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/tcg_card.dart';

class RarityDistributionChart extends StatefulWidget {
  final List<TcgCard> cards;
  
  const RarityDistributionChart({
    Key? key,
    required this.cards,
  }) : super(key: key);

  @override
  State<RarityDistributionChart> createState() => _RarityDistributionChartState();
}

class _RarityDistributionChartState extends State<RarityDistributionChart> {
  int touchedIndex = -1;
  bool _showLabels = false;

  @override
  Widget build(BuildContext context) {
    final rarityMap = <String, int>{};
    
    // Group cards by rarity
    for (final card in widget.cards) {
      final rarity = card.rarity ?? 'Unknown';
      rarityMap[rarity] = (rarityMap[rarity] ?? 0) + 1;
    }
    
    // Convert to sorted list
    final sortedRarities = rarityMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Generate color scheme
    final colors = [
      const Color(0xFF845EC2), 
      const Color(0xFFD65DB1), 
      const Color(0xFFFF6F91), 
      const Color(0xFFFF9671), 
      const Color(0xFFFFC75F), 
      const Color(0xFFF9F871),
      const Color(0xFF2C73D2),
      const Color(0xFF008E9B),
    ];
    
    // Create sections
    final sections = <PieChartSectionData>[];
    
    for (var i = 0; i < sortedRarities.length; i++) {
      final entry = sortedRarities[i];
      final isSelected = (touchedIndex == i);
      final percentage = (entry.value / widget.cards.length) * 100;
      
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: isSelected ? 90 : 80, // Even larger radius for bigger pie chart
          titleStyle: TextStyle(
            fontSize: isSelected ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black26, blurRadius: 2),
            ],
          ),
          badgeWidget: isSelected ? _Badge(
            entry.key,
            size: 50, // Larger badge
            borderColor: colors[i % colors.length],
          ) : null,
          badgePositionPercentageOffset: .98,
        ),
      );
    }

    return Column(
      children: [
        // Add toggle for labels
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Show Labels',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Switch(
              value: _showLabels,
              onChanged: (value) {
                setState(() {
                  _showLabels = value;
                });
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        
        // Main content
        Expanded(
          child: _showLabels 
            ? _buildChartWithLabels(sections, sortedRarities, colors)
            : _buildLargeChart(sections),
        ),
      ],
    );
  }
  
  Widget _buildLargeChart(List<PieChartSectionData> sections) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1, // Make it a perfect square
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Add padding for more space
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    setState(() => touchedIndex = -1);
                    return;
                  }
                  
                  setState(() => touchedIndex = 
                    pieTouchResponse.touchedSection!.touchedSectionIndex);
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 0,
              sections: sections.map((section) => 
                // Increase radius for bigger chart
                PieChartSectionData(
                  color: section.color,
                  value: section.value,
                  title: section.title,
                  radius: section.radius + 15, // Make sections even larger
                  titleStyle: section.titleStyle,
                  badgeWidget: section.badgeWidget,
                  badgePositionPercentageOffset: section.badgePositionPercentageOffset,
                )
              ).toList(),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildChartWithLabels(List<PieChartSectionData> sections, 
      List<MapEntry<String, int>> sortedRarities, List<Color> colors) {
    // For label mode, we need to handle the overflow by using a ListView
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Add the pie chart with larger height for a bigger chart
        SizedBox(
          height: 240, // Increased from 200 to make the chart bigger
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Add padding for more space
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          setState(() => touchedIndex = -1);
                          return;
                        }
                        
                        setState(() => touchedIndex = 
                          pieTouchResponse.touchedSection!.touchedSectionIndex);
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    sections: sections.map((section) => 
                      // Increase radius for bigger chart
                      PieChartSectionData(
                        color: section.color,
                        value: section.value,
                        title: section.title,
                        radius: section.radius + 15, // Make sections even larger
                        titleStyle: section.titleStyle,
                        badgeWidget: section.badgeWidget,
                        badgePositionPercentageOffset: section.badgePositionPercentageOffset,
                      )
                    ).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Add a separate legend section below the chart
        const SizedBox(height: 16), // Add space between chart and legend
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(
              sortedRarities.length,
              (index) {
                final entry = sortedRarities[index];
                final percentage = (entry.value / widget.cards.length * 100).toStringAsFixed(1);
                
                return _IndicatorWidget(
                  color: colors[index % colors.length],
                  text: '${entry.key} (${entry.value}) - ${percentage}%',
                  isSquare: true,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(
    this.text, {
    required this.size,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: FittedBox(
          child: Text(
            text,
            style: TextStyle(
              fontSize: size * .2,
              fontWeight: FontWeight.bold,
              color: borderColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicatorWidget extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const _IndicatorWidget({
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor = const Color(0xff505050),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
            borderRadius: isSquare ? BorderRadius.circular(3) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : textColor,
          ),
        )
      ],
    );
  }
}
