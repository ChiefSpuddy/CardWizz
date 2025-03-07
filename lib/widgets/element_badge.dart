import 'package:flutter/material.dart';

// Reusable widget for displaying elemental types in the Card Arena
class ElementBadge extends StatelessWidget {
  final String element;
  final double size;
  final bool isOutlined;
  
  const ElementBadge({
    super.key,
    required this.element,
    this.size = 1.0,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = _getElementColor(element.toLowerCase());
    final double fontSize = 12 * size;
    final double paddingHorizontal = 8 * size;
    final double paddingVertical = 4 * size;
    final double borderRadius = 12 * size;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(borderRadius),
        border: isOutlined 
            ? Border.all(color: color, width: 1.5) 
            : null,
      ),
      child: Text(
        element.toUpperCase(),
        style: TextStyle(
          color: isOutlined ? color : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          shadows: isOutlined 
              ? [] 
              : [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2,
                  ),
                ],
        ),
      ),
    );
  }
  
  Color _getElementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'electric':
        return Colors.amber;
      case 'grass':
        return Colors.green;
      case 'psychic':
        return Colors.purple;
      case 'normal':
        return Colors.grey;
      case 'fighting':
        return Colors.brown;
      case 'poison':
        return Colors.deepPurple;
      case 'ground':
        return Colors.amber.shade700;
      case 'flying':
        return Colors.lightBlue;
      case 'bug':
        return Colors.lightGreen;
      case 'rock':
        return Colors.brown.shade300;
      case 'ghost':
        return Colors.indigo;
      case 'dark':
        return Colors.grey.shade800;
      case 'dragon':
        return Colors.indigo.shade400;
      case 'steel':
        return Colors.blueGrey;
      case 'fairy':
        return Colors.pink;
      case 'ice':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}
