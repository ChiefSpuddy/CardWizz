import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../models/battle_result.dart';  // Add this import to fix the BattleResult not found error

class BattleStats {
  final int wins;
  final int losses;
  final int draws;
  final List<BattleResult> recentBattles;

  BattleStats({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.recentBattles,
  });

  double get winRate {
    final total = wins + losses;
    return total == 0 ? 0 : wins / total;
  }

  int get total => wins + losses + draws;
}

class BattleService extends ChangeNotifier {
  static const String _statsKey = 'battle_stats';
  static const String _recentBattlesKey = 'recent_battles';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;
  final List<BattleResult> _recentBattles = [];

  Future<void> saveStats({
    required int wins,
    required int losses,
    required int draws,
    required List<BattleResult> recentBattles,
  }) async {
    _wins = wins;
    _losses = losses;
    _draws = draws;
    _recentBattles.clear();
    _recentBattles.addAll(recentBattles);
    notifyListeners();

    // Save to secure storage
    try {
      final statsJson = jsonEncode({
        'wins': wins,
        'losses': losses,
        'draws': draws,
      });
      
      await _secureStorage.write(key: _statsKey, value: statsJson);
      
      // Store only the 10 most recent battles to save space
      final battlesToSave = recentBattles.take(10).toList();
      final battlesJson = jsonEncode(
        battlesToSave.map((battle) => battle.toJson()).toList(),
      );
      await _secureStorage.write(key: _recentBattlesKey, value: battlesJson);
    } catch (e) {
      debugPrint('Failed to save battle stats: $e');
    }
  }

  Future<BattleStats> getBattleStats() async {
    try {
      // Load stats from secure storage
      final statsJson = await _secureStorage.read(key: _statsKey);
      final battlesJson = await _secureStorage.read(key: _recentBattlesKey);
      
      if (statsJson != null) {
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        _wins = stats['wins'] ?? 0;
        _losses = stats['losses'] ?? 0;
        _draws = stats['draws'] ?? 0;
      }
      
      _recentBattles.clear();
      if (battlesJson != null) {
        final battles = jsonDecode(battlesJson) as List;
        _recentBattles.addAll(
          battles.map((json) => BattleResult.fromJson(json)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Failed to load battle stats: $e');
    }
    
    return BattleStats(
      wins: _wins,
      losses: _losses,
      draws: _draws,
      recentBattles: _recentBattles,
    );
  }
  
  // Clear all saved battle data (useful for testing)
  Future<void> clearBattleData() async {
    try {
      await _secureStorage.delete(key: _statsKey);
      await _secureStorage.delete(key: _recentBattlesKey);
      
      _wins = 0;
      _losses = 0;
      _draws = 0;
      _recentBattles.clear();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear battle data: $e');
    }
  }
}