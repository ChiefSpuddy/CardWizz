import '../models/tcg_card.dart';
import '../models/battle_stats.dart';

class BattleResult {
  final TcgCard userCard;
  final TcgCard opponentCard;
  final String result; // 'win', 'loss', or 'draw'
  final DateTime timestamp;
  final double userPoints;
  final double opponentPoints;
  final List<BattleMove>? battleMoves; // Added for battle sequence
  final CardBattleStats? userStats; // Added detailed stats
  final CardBattleStats? opponentStats; // Added detailed stats
  final String? winningMove; // Added for dramatic effect
  
  BattleResult({
    required this.userCard,
    required this.opponentCard,
    required this.result,
    required this.timestamp,
    required this.userPoints,
    required this.opponentPoints,
    this.battleMoves,
    this.userStats,
    this.opponentStats,
    this.winningMove,
  });
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userCard': userCard.toJson(),
      'opponentCard': opponentCard.toJson(),
      'result': result,
      'timestamp': timestamp.toIso8601String(),
      'userPoints': userPoints,
      'opponentPoints': opponentPoints,
      'winningMove': winningMove,
    };
  }
  
  // Create from JSON
  factory BattleResult.fromJson(Map<String, dynamic> json) {
    return BattleResult(
      userCard: TcgCard.fromJson(json['userCard']),
      opponentCard: TcgCard.fromJson(json['opponentCard']),
      result: json['result'],
      timestamp: DateTime.parse(json['timestamp']),
      userPoints: json['userPoints'].toDouble(),
      opponentPoints: json['opponentPoints'].toDouble(),
      winningMove: json['winningMove'],
    );
  }
  
  // Helper for calculating win ratio
  static double calculateWinRate(int wins, int total) {
    if (total == 0) return 0;
    return wins / total;
  }
}

// Added for battle narrative
class BattleMove {
  final String attacker; // 'user' or 'opponent'
  final String moveName;
  final double damage;
  final bool isCritical;
  final bool isSpecial;
  final String? effectDescription;
  final String? animationType; // Added for animation variety
  
  BattleMove({
    required this.attacker,
    required this.moveName,
    required this.damage,
    this.isCritical = false,
    this.isSpecial = false,
    this.effectDescription,
    this.animationType,
  });

  // Helper to get animation path based on move properties
  String? get animationAsset {
    if (isSpecial) {
      if (animationType == 'fire') return 'assets/animations/fire_effect.json';
      if (animationType == 'water') return 'assets/animations/water_effect.json';
      if (animationType == 'electric') return 'assets/animations/electric_effect.json';
      return 'assets/animations/special_effect.json';
    }
    
    if (isCritical) {
      return 'assets/animations/critical_effect.json';
    }
    
    return 'assets/animations/normal_attack.json';
  }

  Map<String, dynamic> toJson() {
    return {
      'attacker': attacker,
      'moveName': moveName,
      'damage': damage,
      'isCritical': isCritical,
      'isSpecial': isSpecial,
      'effectDescription': effectDescription,
      'animationType': animationType,
    };
  }

  factory BattleMove.fromJson(Map<String, dynamic> json) {
    return BattleMove(
      attacker: json['attacker'],
      moveName: json['moveName'],
      damage: json['damage'].toDouble(),
      isCritical: json['isCritical'] ?? false,
      isSpecial: json['isSpecial'] ?? false,
      effectDescription: json['effectDescription'],
      animationType: json['animationType'],
    );
  }
}
