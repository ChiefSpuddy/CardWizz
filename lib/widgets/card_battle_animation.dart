import 'package:flutter/material.dart';
import 'dart:math';
import '../models/tcg_card.dart';
import '../models/battle_stats.dart';
import '../models/battle_result.dart';
import 'package:lottie/lottie.dart';

class CardBattleAnimation extends StatefulWidget {
  final TcgCard userCard;
  final TcgCard cpuCard;
  final AnimationController animationController;
  final CardBattleStats? userStats;
  final CardBattleStats? cpuStats;
  final Function(List<BattleMove>) onBattleComplete;

  const CardBattleAnimation({
    super.key,
    required this.userCard,
    required this.cpuCard,
    required this.animationController,
    this.userStats,
    this.cpuStats,
    required this.onBattleComplete,
  });

  @override
  State<CardBattleAnimation> createState() => _CardBattleAnimationState();
}

class _CardBattleAnimationState extends State<CardBattleAnimation> with SingleTickerProviderStateMixin {
  List<BattleMove> _battleMoves = [];
  int _currentMoveIndex = 0;
  double _userHealth = 100;
  double _cpuHealth = 100;
  bool _battleComplete = false;
  late AnimationController _shakeController;
  String _battleText = 'Battle Begin!';
  String _currentElement = 'normal';
  bool _showMoveAnimation = false;
  String _currentMoveName = '';
  
  // More interesting move names for variety
  final List<String> _attackMoves = [
    'Quick Attack', 'Power Strike', 'Body Slam', 'Swift',
    'Tackle', 'Fury Swipes', 'Slash', 'Mega Kick', 'Double Slap',
    'Comet Punch', 'Stomp', 'Mega Punch', 'Take Down'
  ];
  
  final List<String> _specialMoves = [
    'Hyper Beam', 'Solar Beam', 'Fire Blast', 'Thunder', 
    'Blizzard', 'Psychic', 'Dream Eater', 'Sky Attack', 
    'Hydro Pump', 'Flamethrower', 'Thunderbolt', 'Ice Beam',
    'Psychokinesis', 'Dragon Rage', 'Shadow Ball'
  ];

  final Map<String, String> _elementAnimations = {
    'fire': 'assets/animations/fire_effect.json',
    'water': 'assets/animations/water_effect.json',
    'electric': 'assets/animations/electric_effect.json',
    'grass': 'assets/animations/earth_effect.json',
    'psychic': 'assets/animations/psychic_effect.json',
    'normal': 'assets/animations/battle_effect.json',
    'dark': 'assets/animations/battle_effect.json',
    'fairy': 'assets/animations/battle_effect.json',
    'dragon': 'assets/animations/battle_effect.json',
    'steel': 'assets/animations/battle_effect.json',
    'ice': 'assets/animations/water_effect.json',
    'ghost': 'assets/animations/psychic_effect.json',
    'fighting': 'assets/animations/earth_effect.json',
    'poison': 'assets/animations/battle_effect.json',
    'ground': 'assets/animations/earth_effect.json',
    'flying': 'assets/animations/battle_effect.json',
    'bug': 'assets/animations/battle_effect.json',
    'rock': 'assets/animations/earth_effect.json',
  };
  
  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _generateBattleSequence();
    _startBattleSimulation();
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }
  
  void _generateBattleSequence() {
    final random = Random();
    _battleMoves = [];
    
    // First move always by user
    String firstMoveName = _getMoveNameForCard(widget.userStats?.element ?? 'normal', false);
    double userDamage = _calculateDamage(widget.userStats, widget.cpuStats, false);
    
    _battleMoves.add(BattleMove(
      attacker: 'user',
      moveName: firstMoveName,
      damage: userDamage,
    ));
    
    // CPU counters
    String cpuMoveName = _getMoveNameForCard(widget.cpuStats?.element ?? 'normal', false);
    double cpuDamage = _calculateDamage(widget.cpuStats, widget.userStats, false);
    
    _battleMoves.add(BattleMove(
      attacker: 'opponent',
      moveName: cpuMoveName,
      damage: cpuDamage,
    ));
    
    // Special move for user (with chance of critical)
    bool isCritical = random.nextDouble() < 0.3; // 30% chance of critical
    String specialMoveName = _getMoveNameForCard(widget.userStats?.element ?? 'normal', true);
    double specialDamage = _calculateDamage(widget.userStats, widget.cpuStats, true) * (isCritical ? 1.5 : 1.0);
    
    _battleMoves.add(BattleMove(
      attacker: 'user',
      moveName: specialMoveName,
      damage: specialDamage,
      isSpecial: true,
      isCritical: isCritical,
      effectDescription: isCritical ? 'Critical Hit!' : 'Super Effective!',
    ));
    
    // Final CPU move - potentially desperate counter
    bool cpuSpecial = random.nextDouble() < 0.5; // 50% chance of special move
    String finalMoveName = _getMoveNameForCard(widget.cpuStats?.element ?? 'normal', cpuSpecial);
    double finalDamage = _calculateDamage(widget.cpuStats, widget.userStats, cpuSpecial);
    
    _battleMoves.add(BattleMove(
      attacker: 'opponent',
      moveName: finalMoveName,
      damage: finalDamage,
      isSpecial: cpuSpecial,
    ));
  }
  
  String _getMoveNameForCard(String element, bool isSpecial) {
    final random = Random();
    
    // Select appropriate move list
    final moveList = isSpecial ? _specialMoves : _attackMoves;
    
    // Add element prefix to some special moves for flavor
    if (isSpecial && random.nextBool()) {
      final baseName = moveList[random.nextInt(moveList.length)];
      
      switch (element.toLowerCase()) {
        case 'fire':
          return 'Fire $baseName';
        case 'water':
          return 'Water $baseName';
        case 'electric':
          return 'Thunder $baseName';
        case 'grass':
          return 'Leaf $baseName';
        case 'psychic':
          return 'Psychic $baseName';
        default:
          return baseName;
      }
    }
    
    // Otherwise just return a random move name
    return moveList[random.nextInt(moveList.length)];
  }
  
  double _calculateDamage(CardBattleStats? attacker, CardBattleStats? defender, bool isSpecial) {
    final random = Random();
    
    // Default damage if stats not available
    double damage = 10 + random.nextDouble() * 10; // 10-20 base damage
    
    // If we have stats, use them
    if (attacker != null) {
      // Base damage from stats
      if (isSpecial) {
        damage = attacker.specialPower * (0.8 + random.nextDouble() * 0.4); // 80-120% of special power
      } else {
        damage = attacker.attackPower * (0.8 + random.nextDouble() * 0.4); // 80-120% of attack power
      }
      
      // Apply defense if defender stats exist
      if (defender != null) {
        double defenseValue = isSpecial ? defender.specialPower * 0.3 : defender.defensePower * 0.5;
        damage = max(damage - defenseValue, damage * 0.2); // Defense reduces damage but never below 20%
        
        // Apply elemental multiplier
        damage *= attacker.getElementalMultiplier(defender);
      }
      
      // Add small random variance
      damage *= (0.9 + random.nextDouble() * 0.2); // ±10% variance
    }
    
    return damage;
  }
  
  void _startBattleSimulation() {
    _currentMoveIndex = 0;
    _userHealth = 100;
    _cpuHealth = 100;
    _executeNextMove();
  }
  
  Future<void> _executeNextMove() async {
    if (_currentMoveIndex >= _battleMoves.length) {
      // Battle complete
      if (!_battleComplete) {
        setState(() => _battleComplete = true);
        widget.onBattleComplete(_battleMoves);
      }
      return;
    }
    
    final move = _battleMoves[_currentMoveIndex];
    
    // Update battle text and show the move name animation
    setState(() {
      _battleText = _getBattleMoveText(move);
      _currentElement = _getElementFromMove(move);
      _currentMoveName = move.moveName;
      _showMoveAnimation = true;
    });
    
    // Show the move name animation for a moment
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Apply damage and shake effect
    _shakeController.reset();
    _shakeController.forward();
    
    // Calculate what percentage of health to reduce for more gradual reduction
    // Use about 15-35% of health per hit for better visual effect
    double damagePercentage;
    if (move.attacker == 'user') {
      // Scale damage for visual purposes - aim for 20-30% damage per move
      damagePercentage = min(30, max(15, move.damage * 100 / (widget.cpuStats?.defensePower ?? 30)));
      setState(() {
        _cpuHealth = max(0, _cpuHealth - damagePercentage);
      });
    } else {
      damagePercentage = min(30, max(15, move.damage * 100 / (widget.userStats?.defensePower ?? 30)));
      setState(() {
        _userHealth = max(0, _userHealth - damagePercentage);
      });
    }
    
    // Wait for animation
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Hide the move animation
    setState(() {
      _showMoveAnimation = false;
    });
    
    // Wait a moment between moves
    await Future.delayed(const Duration(milliseconds: 700));
    
    // Ensure we don't go to zero health until the final move
    if (_currentMoveIndex == _battleMoves.length - 1) {
      // For the last move, we can let health go to zero if needed
    } else {
      // Otherwise ensure at least 20% health remains
      if (move.attacker == 'user' && _cpuHealth < 20) {
        setState(() => _cpuHealth = 20);
      } else if (move.attacker == 'opponent' && _userHealth < 20) {
        setState(() => _userHealth = 20);
      }
    }
    
    // Next move
    _currentMoveIndex++;
    if (mounted) {
      _executeNextMove();
    }
  }
  
  String _getBattleMoveText(BattleMove move) {
    final pokemonName = move.attacker == 'user' 
        ? widget.userCard.name 
        : widget.cpuCard.name;
        
    String text = '$pokemonName used ${move.moveName}';
    
    if (move.isCritical) {
      text += ' - Critical Hit!';
    } else if (move.isSpecial) {
      text += ' - It\'s super effective!';
    }
    
    return text;
  }
  
  String _getElementFromMove(BattleMove move) {
    final element = move.attacker == 'user'
        ? widget.userStats?.element
        : widget.cpuStats?.element;
        
    return element?.toLowerCase() ?? 'normal';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Replace image background with gradient
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.blueGrey.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Battle effect animation
          if (_currentElement != null && _elementAnimations.containsKey(_currentElement))
            Positioned.fill(
              child: Opacity(
                opacity: 0.7,
                child: Lottie.asset(
                  _elementAnimations[_currentElement] ?? 'assets/animations/battle_effect.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
          // Battle content
          SafeArea(
            child: Column(
              children: [
                // CPU health bar - use the enhanced health bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: _buildHealthBar(widget.cpuCard.name, _cpuHealth, true),
                ),
                
                // CPU card - continue with the existing animation logic
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final bool isBeingAttacked = _currentMoveIndex < _battleMoves.length && 
                        _battleMoves[_currentMoveIndex].attacker == 'user';
                    
                    return Transform.translate(
                      offset: isBeingAttacked
                          ? Offset(
                              sin(_shakeController.value * 10) * 5,
                              0,
                            )
                          : Offset.zero,
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildCardImage(widget.cpuCard.imageUrl),
                      ),
                      
                      // Move name display for CPU
                      if (_showMoveAnimation && _battleMoves[_currentMoveIndex].attacker == 'opponent')
                        Positioned(
                          top: 0,
                          child: _buildMoveNameDisplay(),
                        ),
                    ],
                  ),
                ),
                
                // Battle info box - enhance with gradient
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black54,
                            Colors.black38,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _battleText,
                          key: ValueKey<String>(_battleText),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // User card - continue with the existing animation logic
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final bool isBeingAttacked = _currentMoveIndex < _battleMoves.length && 
                        _battleMoves[_currentMoveIndex].attacker == 'opponent';
                    
                    return Transform.translate(
                      offset: isBeingAttacked
                          ? Offset(
                              sin(_shakeController.value * 10) * 5,
                              0,
                            )
                          : Offset.zero,
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildCardImage(widget.userCard.imageUrl),
                      ),
                      
                      // Move name display for user
                      if (_showMoveAnimation && _battleMoves[_currentMoveIndex].attacker == 'user')
                        Positioned(
                          bottom: 0,
                          child: _buildMoveNameDisplay(),
                        ),
                    ],
                  ),
                ),
                
                // User health bar - use the enhanced health bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: _buildHealthBar(widget.userCard.name, _userHealth, false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMoveNameDisplay() {
    final move = _currentMoveIndex < _battleMoves.length ? _battleMoves[_currentMoveIndex] : null;
    final Color effectColor = move?.isCritical ?? false 
        ? Colors.redAccent 
        : move?.isSpecial ?? false 
            ? Colors.purpleAccent 
            : Colors.cyanAccent;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        // Clamp the value to prevent opacity from going outside the valid range
        final clampedOpacity = value.clamp(0.0, 1.0);
        
        return Opacity(
          opacity: clampedOpacity, // Use clamped value for opacity
          child: Transform.scale(
            scale: 0.5 + (value * 0.5), // Original value is fine for scaling
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: effectColor.withOpacity(0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectColor.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (move?.isSpecial ?? false)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        move?.isCritical ?? false ? Icons.flash_on : Icons.auto_awesome,
                        color: effectColor,
                        size: 16,
                      ),
                    ),
                  Text(
                    _currentMoveName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: effectColor.withOpacity(0.8),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHealthBar(String name, double health, bool isOpponent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${health.toInt()}%',
                style: TextStyle(
                  color: _getHealthColor(health),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            // Background bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            // Health bar with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              height: 12,
              width: MediaQuery.of(context).size.width * 0.8 * (health / 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getHealthColor(health).withOpacity(0.7),
                    _getHealthColor(health),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: health > 50 ? [
                  BoxShadow(
                    color: _getHealthColor(health).withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ] : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Add error handling for network images
  Widget _buildCardImage(String imageUrl) {
    return Image.network(
      imageUrl,
      height: 180,
      width: 120, // Add fixed width to ensure consistent sizing
      fit: BoxFit.contain,
      // Add error handling for 404s
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading battle card image: $error');
        return Container(
          height: 180,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 40,
              ),
              SizedBox(height: 8),
              Text(
                'Image not found',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 180,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white70,
            ),
          ),
        );
      },
    );
  }
  
  Color _getHealthColor(double health) {
    if (health > 65) return Colors.green;
    if (health > 30) return Colors.orange;
    return Colors.red;
  }
}
