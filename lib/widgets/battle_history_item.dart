import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/battle_result.dart';

class BattleHistoryItem extends StatelessWidget {
  final BattleResult result;
  final VoidCallback? onTap;
  
  const BattleHistoryItem({
    super.key, 
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String resultText = result.result == 'win' 
        ? 'Victory' 
        : result.result == 'loss' 
            ? 'Defeat' 
            : 'Draw';
            
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Battle result and date
              Row(
                children: [
                  Icon(
                    result.result == 'win' 
                        ? Icons.emoji_events 
                        : result.result == 'loss' 
                            ? Icons.cancel_outlined
                            : Icons.remove_circle_outline,
                    color: result.result == 'win' 
                        ? Colors.amber 
                        : result.result == 'loss' 
                            ? Colors.red 
                            : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    resultText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: result.result == 'win' 
                          ? Colors.amber 
                          : result.result == 'loss' 
                              ? Colors.red 
                              : null,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d').format(result.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              
              // Cards comparison
              Row(
                children: [
                  // Your card
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            result.userCard.imageUrl,
                            height: 70,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 70,
                                width: 50,
                                color: Colors.grey[800],
                                child: Icon(Icons.broken_image, color: Colors.white60, size: 24),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Score - Fix overflow here
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Fix the overflow in this Row by reducing font size and adding constraints
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // User score with constrained width
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    result.userPoints.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16, // Reduced from 18
                                      color: result.result == 'win' ? Colors.green : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4), // Reduced width
                                const Text(
                                  'VS',
                                  style: TextStyle(
                                    fontSize: 10, // Reduced from 12
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4), // Reduced width
                                // Opponent score with constrained width
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    result.opponentPoints.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16, // Reduced from 18
                                      color: result.result == 'loss' ? Colors.green : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        
                        // Make sure winning move text doesn't overflow
                        if (result.winningMove != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.4,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              result.winningMove!,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Opponent card
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            result.opponentCard.imageUrl,
                            height: 70,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 70,
                                width: 50,
                                color: Colors.grey[800],
                                child: Icon(Icons.broken_image, color: Colors.white60, size: 24),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Card names - Fix overflow here too
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    // Constrain text width for user card name
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 50,
                          maxWidth: 120,
                        ),
                        child: Text(
                          result.userCard.name,
                          style: const TextStyle(
                            fontSize: 11, // Reduced from 12
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                    // Add flexible space between names
                    const Spacer(),
                    
                    // Constrain text width for opponent card name
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 50,
                          maxWidth: 120,
                        ),
                        child: Text(
                          result.opponentCard.name,
                          style: const TextStyle(
                            fontSize: 11, // Reduced from 12
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
