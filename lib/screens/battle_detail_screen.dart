import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/battle_result.dart';
import '../widgets/animated_background.dart';
import '../widgets/element_badge.dart';
import '../widgets/move_list_item.dart';
import '../models/battle_stats.dart';

class BattleDetailScreen extends StatelessWidget {
  final BattleResult battle;
  
  const BattleDetailScreen({
    super.key,
    required this.battle,
  });

  @override
  Widget build(BuildContext context) {
    final isWin = battle.result == 'win';
    final isDraw = battle.result == 'draw';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Battle Details'),
      ),
      body: AnimatedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and result banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isWin 
                        ? [Colors.green, Colors.green.shade800] 
                        : isDraw 
                            ? [Colors.amber, Colors.amber.shade800]
                            : [Colors.red, Colors.red.shade800],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWin 
                              ? 'VICTORY!' 
                              : isDraw 
                                  ? 'DRAW!' 
                                  : 'DEFEAT!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM d, yyyy - h:mm a').format(battle.timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isWin 
                          ? Icons.emoji_events 
                          : isDraw 
                              ? Icons.remove_circle_outline
                              : Icons.cancel_outlined,
                      color: Colors.white,
                      size: 36,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Cards comparison with detailed stats
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'BATTLE CARDS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User card
                          Expanded(
                            child: _buildCardWithStats(
                              context,
                              battle.userCard.imageUrl,
                              battle.userCard.name,
                              battle.userStats,
                              battle.userPoints,
                              isWinner: isWin,
                            ),
                          ),
                          
                          // VS divider
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            height: 220,
                            width: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          
                          // Opponent card
                          Expanded(
                            child: _buildCardWithStats(
                              context,
                              battle.opponentCard.imageUrl,
                              battle.opponentCard.name,
                              battle.opponentStats,
                              battle.opponentPoints,
                              isWinner: !isWin && !isDraw,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Battle moves
              if (battle.battleMoves != null && battle.battleMoves!.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BATTLE SEQUENCE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        ...battle.battleMoves!.map((move) => MoveListItem(
                          move: move,
                          userCardName: battle.userCard.name,
                          opponentCardName: battle.opponentCard.name,
                        )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardWithStats(
    BuildContext context,
    String imageUrl,
    String name,
    CardBattleStats? stats,
    double points,
    {required bool isWinner}
  ) {
    return Column(
      children: [
        // Card image
        Stack(
          alignment: Alignment.center,
          children: [
            // Card
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
            
            // Winner badge
            if (isWinner)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Card name
        Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Points
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isWinner ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Power: ${points.toStringAsFixed(1)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWinner ? Colors.green : null,
            ),
          ),
        ),
        
        // Element badge if available
        if (stats != null)
          ElementBadge(element: stats.element),
      ],
    );
  }
}
