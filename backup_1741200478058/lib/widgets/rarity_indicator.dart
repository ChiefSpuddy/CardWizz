import 'package:flutter/material.dart';

/// A reusable widget to display card rarity with appropriate color
class RarityIndicator extends StatelessWidget {
  final String rarity;
  final bool showText;
  final double size;

  const RarityIndicator({
    super.key,
    required this.rarity,
    this.showText = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final rarityText = _getRarityText();
    final rarityColor = _getRarityColor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: rarityColor,
            shape: BoxShape.circle,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            rarityText,
            style: TextStyle(
              color: rarityColor,
              fontWeight: FontWeight.bold,
              fontSize: size * 1.1,
            ),
          ),
        ],
      ],
    );
  }

  String _getRarityText() {
    final normalized = rarity.toLowerCase().trim();
    if (normalized == 'mythic' || normalized == 'mythic rare') return 'Mythic';
    if (normalized == 'rare') return 'Rare';
    if (normalized == 'uncommon') return 'Uncommon';
    if (normalized == 'common') return 'Common';
    if (normalized == 'special') return 'Special';
    return rarity;
  }

  Color _getRarityColor() {
    final normalized = rarity.toLowerCase().trim();
    if (normalized == 'mythic' || normalized == 'mythic rare' || normalized == 'ultra rare') {
      return Colors.orange.shade700;
    }
    if (normalized == 'rare' || normalized == 'holo rare' || normalized == 'holofoil rare') {
      return Colors.amber.shade600;
    }
    if (normalized == 'uncommon') return Colors.grey.shade500;
    if (normalized == 'common') return Colors.black54;
    if (normalized == 'special' || normalized == 'promo') {
      return Colors.purple.shade400;
    }
    return Colors.teal.shade500; // Default color
  }
}
