import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/battle_service.dart';
import '../providers/app_state.dart';
import 'card_arena_screen.dart';
import '../models/battle_result.dart';
import '../widgets/battle_history_item.dart';
import 'battle_detail_screen.dart';

class CardArenaHome extends StatefulWidget {
  const CardArenaHome({super.key});

  @override
  State<CardArenaHome> createState() => _CardArenaHomeState();
}

class _CardArenaHomeState extends State<CardArenaHome> {
  bool _isLoading = true;
  List<BattleResult> _recentBattles = [];
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;

  @override
  void initState() {
    super.initState();
    _loadBattleStats();
  }

  Future<void> _loadBattleStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final battleService = Provider.of<BattleService>(context, listen: false);
      final stats = await battleService.getBattleStats();

      setState(() {
        _wins = stats.wins;
        _losses = stats.losses;
        _draws = stats.draws;
        _recentBattles = stats.recentBattles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading battle stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('Card Arena'),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.purple.shade800,
                            Colors.deepPurple.shade900,
                          ],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Animated particles for dynamic effect
                          for (var i = 0; i < 20; i++)
                            Positioned(
                              left: 20.0 + (i * 15),
                              top: 40.0 + (i * 10 % 120),
                              child: AnimatedBuilder(
                                animation: const AlwaysStoppedAnimation(0),
                                builder: (context, child) {
                                  return Container(
                                    width: 4 + (i % 4),
                                    height: 4 + (i % 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3 + (i % 7) * 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Battle logo or icon
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 40.0),
                              child: Icon(
                                Icons.sports_kabaddi,
                                size: 60,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildStatsOverview(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildStartBattleCard(),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Recent Battles',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._buildRecentBattles(),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsOverview() {
    final total = _wins + _losses + _draws;
    final winRate = total > 0 ? (_wins / total) * 100 : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Battle Record',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Wins', _wins, Colors.green),
                _buildStatItem('Losses', _losses, Colors.red),
                _buildStatItem('Draws', _draws, Colors.amber),
                _buildStatItem('Win Rate', winRate.toStringAsFixed(1) + '%', 
                    _getWinRateColor(winRate / 100)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          value is int ? '$value' : value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getWinRateColor(double winRate) {
    if (winRate >= 0.7) return Colors.green;
    if (winRate >= 0.5) return Colors.lime;
    if (winRate >= 0.3) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStartBattleCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CardArenaScreen(),
            ),
          ).then((_) => _loadBattleStats());
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.shade700,
                Colors.deepOrange.shade900,
              ],
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Icon(
                Icons.flash_on,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start New Battle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Test your cards against opponents',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecentBattles() {
    if (_recentBattles.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No recent battles. Start a battle to see your history!'),
          ),
        ),
      ];
    }

    return _recentBattles.map((battle) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: BattleHistoryItem(
          result: battle,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BattleDetailScreen(battle: battle),
              ),
            );
          },
        ),
      );
    }).toList();
  }
}
