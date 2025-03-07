import 'package:flutter/material.dart';
import '../models/battle_result.dart';

class MoveListItem extends StatelessWidget {
  final BattleMove move;
  final String userCardName;
  final String opponentCardName;
  
  const MoveListItem({
    super.key,
    required this.move,
    required this.userCardName,
    required this.opponentCardName,
  });

  @override
  Widget build(BuildContext context) {
    final isUserMove = move.attacker == 'user';
    final cardName = isUserMove ? userCardName : opponentCardName;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getMoveColor(move).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getMoveColor(move).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Attack type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getMoveColor(move).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getMoveIcon(move),
              color: _getMoveColor(move),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Move details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  move.moveName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$cardName used this move',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          
          // Damage info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: _getMoveColor(move),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${move.damage.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getMoveColor(move),
                    ),
                  ),
                ],
              ),
              
              if (move.isCritical || move.isSpecial) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getMoveColor(move).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    move.isCritical ? 'CRITICAL' : 'SPECIAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getMoveColor(move),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getMoveColor(BattleMove move) {
    if (move.isCritical) return Colors.red;
    if (move.isSpecial) return Colors.purple;
    return move.attacker == 'user' ? Colors.blue : Colors.orange;
  }
  
  IconData _getMoveIcon(BattleMove move) {
    if (move.isCritical) return Icons.whatshot;
    if (move.isSpecial) return Icons.auto_awesome;
    return move.attacker == 'user' ? Icons.arrow_forward : Icons.arrow_back;
  }
}
