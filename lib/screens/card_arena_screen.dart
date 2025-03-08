import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // Add this import for Lottie
import '../models/tcg_card.dart';
import '../services/storage_service.dart';
import '../providers/currency_provider.dart';
import '../widgets/animated_background.dart';
import '../providers/app_state.dart';
import '../widgets/sign_in_view.dart';
import '../widgets/card_battle_animation.dart';
import '../widgets/battle_stats_card.dart';
import '../widgets/battle_history_item.dart';
import '../services/battle_service.dart';
import '../models/battle_result.dart';
import '../widgets/styled_toast.dart';
import '../models/battle_stats.dart'; // This import is fine now that we removed duplicates
import 'dart:ui';
import '../widgets/styled_button.dart';
import '../services/tcg_api_service.dart'; // Add this import
import '../widgets/empty_collection_view.dart'; // Add this import
import '../widgets/standard_app_bar.dart'; // Add this import

class CardArenaScreen extends StatefulWidget {
  const CardArenaScreen({super.key});

  @override
  State<CardArenaScreen> createState() => _CardArenaScreenState();
}

class _CardArenaScreenState extends State<CardArenaScreen> with SingleTickerProviderStateMixin {
  // States: selecting, battling, results, card_selection
  String _currentState = 'selecting';
  
  // Selected cards
  TcgCard? _userCard;
  TcgCard? _cpuCard;
  List<TcgCard> _userCards = [];
  
  // Animation controller
  late AnimationController _animationController;
  
  // Battle history
  final List<BattleResult> _battleHistory = [];
  
  // User stats
  int _wins = 0;
  int _losses = 0;
  int _draws = 0;
  
  // Recently used cards to avoid repetition
  final Set<String> _recentlyUsedCardIds = {};
  
  // Add these new properties for enhanced battles
  CardBattleStats? _userCardStats;
  CardBattleStats? _cpuCardStats;
  bool _showBattleIntro = false;
  List<String>? _availableMoves;
  bool _isLoading = false;
  
  // Better opponent management with corrected image URLs
  final List<String> _possibleOpponents = [
    'Charizard', 'Blastoise', 'Venusaur', 'Pikachu', 'Mewtwo', 
    'Gyarados', 'Gengar', 'Alakazam', 'Dragonite', 'Machamp',
    'Articuno', 'Zapdos', 'Moltres', 'Snorlax', 'Lapras'
  ];
  
  // Updated opponent card image URLs to ensure they work
  final Map<String, String> _opponentImages = {
    'Charizard': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/sv/SV3_5/196_384.png',
    'Blastoise': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/swsh/CEC/75.jpg',
    'Venusaur': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/sm/TEU/1.png',
    'Pikachu': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/swsh/VIV/43.png',
    'Mewtwo': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/swsh/CPA/49.png',
    'Gyarados': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/bw/DRX/31.jpg',
    'Gengar': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/swsh/CRE/70.png',
    'Alakazam': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/xy/FCO/25.jpg',
    'Dragonite': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/sm/UNM/119.png',
    'Machamp': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/sm/TEU/71.png',
    'Articuno': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/xy/FCO/17.jpg',
    'Zapdos': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/sm/TEU/40.png',
    'Moltres': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/sm/TEU/8.png',
    'Snorlax': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/sv/SV1S/154.png',
    'Lapras': 'https://limitlesstcg.nyc3.digitaloceanspaces.com/cards/swsh/CPA/12.png',
  };
  
  // Fallback image for error cases
  final String _fallbackImage = 'https://images.pokemontcg.io/base1/4.png'; // Charizard as fallback
  
  // For card selection view
  ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Show intro animation
    _showBattleIntro = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBattleIntro = false);
    });
    
    // Load previous battle stats from secure storage
    _loadBattleStats();
    _loadUserCards();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBattleStats() async {
    final battleService = Provider.of<BattleService>(context, listen: false);
    final stats = await battleService.getBattleStats();
    if (mounted) {
      setState(() {
        _wins = stats.wins;
        _losses = stats.losses;
        _draws = stats.draws;
        _battleHistory.addAll(stats.recentBattles);
      });
    }
  }

  Future<void> _loadUserCards() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      List<TcgCard> userCards = await storageService.getCards();
      
      setState(() {
        _userCards = userCards.where((card) => card.price != null && card.price! > 0).toList();
        
        // Sort by price for better selection
        _userCards.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        
        // Pre-select the first card if available
        if (_userCards.isNotEmpty) {
          _userCard = _userCards.first;
          _userCardStats = CardBattleStats.fromCard(_userCard);
          
          // Generate opponent card
          _generateOpponentCard();
        } else {
          showToast(
            context: context,
            title: 'No Cards Found',
            subtitle: 'Add cards with prices to your collection to battle',
            icon: Icons.warning,
            isError: true,
          );
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cards: $e');
      showToast(
        context: context,
        title: 'Error',
        subtitle: 'Failed to load your cards',
        icon: Icons.error,
        isError: true,
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Update to battle against cards from the user's collection

void _generateOpponentCard() {
  final random = Random();
  
  // Filter out cards that can be used as opponents
  // - Exclude the user's chosen card
  // - Only include cards with prices
  // - Optionally exclude recently used cards for variety
  List<TcgCard> possibleOpponents = _userCards
      .where((card) => 
        card.id != _userCard?.id && 
        card.price != null &&
        card.price! > 0 &&
        !_recentlyUsedCardIds.contains(card.id))
      .toList();
  
  // If we don't have enough cards for opponents, reset the recently used tracking
  if (possibleOpponents.isEmpty) {
    _recentlyUsedCardIds.clear();
    possibleOpponents = _userCards
        .where((card) => card.id != _userCard?.id && card.price != null && card.price! > 0)
        .toList();
  }
  
  // If we still have no valid opponents, create a generic backup opponent
  if (possibleOpponents.isEmpty) {
    // Create a generic opponent with comparable strength
    final opponentCard = TcgCard(
      id: 'cpu-${DateTime.now().millisecondsSinceEpoch}',
      name: "Card Wizard",
      set: TcgSet(id: 'base', name: 'CardWizz Set'),
      number: '${random.nextInt(100) + 1}',
      imageUrl: _fallbackImage,
      rarity: 'Rare',
      price: (_userCard?.price ?? 10.0) * (0.7 + random.nextDouble() * 0.6),
    );
    
    setState(() {
      _cpuCard = opponentCard;
      _cpuCardStats = CardBattleStats.fromCard(opponentCard);
    });
    
    return;
  }
  
  // Choose a random opponent card from filtered list
  final opponentCard = possibleOpponents[random.nextInt(possibleOpponents.length)];
  
  // Track this card to avoid using it in near-future battles
  _recentlyUsedCardIds.add(opponentCard.id);
  
  // Limit the size of recently used cards (e.g., remember last 5 cards)
  if (_recentlyUsedCardIds.length > 5) {
    _recentlyUsedCardIds.remove(_recentlyUsedCardIds.first);
  }
  
  setState(() {
    _cpuCard = opponentCard;
    _cpuCardStats = CardBattleStats.fromCard(opponentCard);
  });
}

  void _selectCard(TcgCard card) {
    setState(() {
      _userCard = card;
      _userCardStats = CardBattleStats.fromCard(card);
      _currentState = 'selecting';
      
      // Regenerate opponent with comparable strength
      _generateOpponentCard();
    });
  }
  
  void _showCardSelection() {
    setState(() {
      _currentState = 'card_selection';
      _searchQuery = '';
    });
  }
  
  // Update the battle intro dialog to reflect that we're battling our own cards
void _startBattle() {
  if (_userCard == null || _cpuCard == null) return;
  
  // Show battle intro dialog with updated title
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "COLLECTION BATTLE",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.red,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User card with animation
              Expanded(  // Add Expanded here to force this section to respect available width
                child: Column(
                  children: [
                    if (_userCard != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _userCard!.imageUrl,
                          height: 120,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      _userCard?.name ?? 'Your Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.black,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      maxLines: 1,  // Limit to 1 line
                      overflow: TextOverflow.ellipsis,  // Add overflow handling
                    ),
                  ],
                ),
              ),
              
              // VS animation - same as before
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),  // Reduce horizontal padding from 20 to 10
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.5 + (value * 0.5),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "VS",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // CPU card with animation - same as before
              Expanded(  // Add Expanded here to force this section to respect available width
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 100.0, end: 0.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(value, 0),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
                      if (_cpuCard != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _cpuCard!.imageUrl,
                            height: 120,
                            width: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        _cpuCard?.name ?? 'Opponent',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,  // Limit to 1 line
                        overflow: TextOverflow.ellipsis,  // Add overflow handling
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  
  // Close dialog after delay
  Future.delayed(const Duration(seconds: 2), () {
    Navigator.of(context).pop();
    
    // Add a countdown before starting the battle
    _showBattleCountdown();
  });
}

// New method for battle countdown
void _showBattleCountdown() {
  int countdown = 3;
  
  setState(() {
    // Use a temporary state to show the countdown
    _currentState = 'countdown';
  });
  
  // Create a separate controller for the dialog state
  final countdownNotifier = ValueNotifier<int>(countdown);
  
  // Show countdown overlay
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    builder: (context) => ValueListenableBuilder<int>(
      valueListenable: countdownNotifier,
      builder: (context, value, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                value > 0 ? '$value' : 'FIGHT!',
                key: ValueKey<int>(value),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: value > 0 ? Colors.amber : Colors.red,
                  shadows: [
                    Shadow(
                      blurRadius: 20,
                      color: value > 0 ? Colors.orange : Colors.redAccent,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  
  // Start countdown timer
  Timer.periodic(Duration(seconds: 1), (timer) {
    countdown--;
    countdownNotifier.value = countdown;
    
    if (countdown < 0) {
      // When countdown reaches 0, actually start the battle
      timer.cancel();
      Navigator.of(context).pop(); // Close countdown dialog
      setState(() {
        _currentState = 'battling';
        _animationController.reset();
        _animationController.forward();
      });
    }
  });
}

// Update the battle points calculation and display

void _completeBattle(List<BattleMove> moves) {
  // Use normalized attack power values instead of raw price
  final userPower = _userCardStats?.attackPower ?? 10.0;
  final cpuPower = _cpuCardStats?.attackPower ?? 10.0;
  
  // Calculate total damage from moves
  double userDamage = moves
      .where((move) => move.attacker == 'user')
      .fold(0, (sum, move) => sum + move.damage);
  
  double cpuDamage = moves
      .where((move) => move.attacker == 'opponent')
      .fold(0, (sum, move) => sum + move.damage);
  
  // Apply normalized power values as multiplier
  final userPoints = userDamage * (userPower / 10);
  final cpuPoints = cpuDamage * (cpuPower / 10);
  
  // Rest of the method remains the same
  String result;
  if (userPoints > cpuPoints) {
    result = 'win';
    _wins++;
  } else if (cpuPoints > userPoints) {
    result = 'loss';
    _losses++;
  } else {
    result = 'draw';
    _draws++;
  }
  
  // Find the winning move (if any)
  String? winningMove;
  if (moves.isNotEmpty) {
    BattleMove? lastMove = moves.last;
    if (lastMove.isCritical) {
      winningMove = "Critical Hit: ${lastMove.moveName}";
    } else if (lastMove.isSpecial) {
      winningMove = "Special Move: ${lastMove.moveName}";
    } else {
      winningMove = lastMove.moveName;
    }
  }
  
  // Create battle result with consistent naming
  final battleResult = BattleResult(
    userCard: _userCard!,
    opponentCard: _cpuCard!,
    result: result,
    timestamp: DateTime.now(),
    userPoints: userPoints,
    opponentPoints: cpuPoints,
    battleMoves: moves,
    userStats: _userCardStats,
    opponentStats: _cpuCardStats,
    winningMove: winningMove,
  );
  
  // Track this card as recently used
  _recentlyUsedCardIds.add(_cpuCard!.id);
    
    // Add to history
    _battleHistory.insert(0, battleResult);
    if (_battleHistory.length > 10) {
      _battleHistory.removeLast();
    }
    
    // Save stats
    final battleService = Provider.of<BattleService>(context, listen: false);
    battleService.saveStats(
      wins: _wins,
      losses: _losses,
      draws: _draws,
      recentBattles: _battleHistory,
    );
    
    setState(() {
      _currentState = 'results';
    });
  }
  
  void _resetBattle() {
    setState(() {
      _currentState = 'selecting';
    });
    
    // Generate new opponent but keep user card
    _generateOpponentCard();
  }
  
  void _filterCards(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
  final isSignedIn = context.watch<AppState>().isAuthenticated;
  
  if (!isSignedIn) {
    return const Scaffold(
      body: SignInView(),
    );
  }

  return Scaffold(
    appBar: StandardAppBar(
      title: _currentState == 'card_selection' ? 'Choose Your Champion' : 'Card Arena',
      actions: _currentState == 'selecting' 
        ? [
            IconButton(
              icon: Icon(
                Icons.swap_horiz,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              onPressed: _showCardSelection,
              tooltip: 'Change Card',
            ),
          ]
        : null,
    ),
    body: _showBattleIntro ? _buildIntroAnimation() : StreamBuilder<List<TcgCard>>(
      stream: Provider.of<StorageService>(context).watchCards(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final cards = snapshot.data!;
        
        // Show empty state if no cards or no cards with prices
        if (cards.isEmpty || !cards.any((card) => card.price != null && card.price! > 0)) {
          return EmptyCollectionView(
            title: 'Battle Arena',
            message: 'Add cards with prices to your collection to battle them against each other',
            buttonText: 'Add Cards',
            icon: Icons.sports_kabaddi,
            uniqueId: 'arena',
          );
        }
        
        return _buildContent();
      },
    ),
  );
}

  
  Widget _buildIntroAnimation() {
    return Stack(
      children: [
        // Background color animation
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade900,
                Colors.deepPurple.shade700,
                Colors.deepPurple.shade800,
              ],
            ),
          ),
          child: Center(
            child: Lottie.asset(
              'assets/animations/battle_intro.json',
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Title text with scale animation
        Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 1),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Text(
                  "CARD ARENA",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.red.shade700,
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildContent() {
  switch (_currentState) {
    case 'card_selection':
      return _buildCardSelectionState();
    case 'battling':
      return _buildBattlingState();
    case 'results':
      return _buildResultsState();
    case 'countdown': // Add this case for the countdown state
      return _buildLoadingView(); // We can reuse the loading view, as the actual countdown is shown in a dialog
    case 'selecting':
    default:
      return _buildSelectingState();
  }
}

  
  Widget _buildCardSelectionState() {
    // Filter cards based on search query
    final filteredCards = _searchQuery.isEmpty 
        ? _userCards 
        : _userCards.where((card) => 
            card.name.toLowerCase().contains(_searchQuery) ||
            (card.setName?.toLowerCase() ?? '').contains(_searchQuery)
          ).toList();
    
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: _filterCards,
            decoration: InputDecoration(
              hintText: 'Search cards...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        
        // Grid of cards
        Expanded(
          child: filteredCards.isEmpty
              ? Center(
                  child: Text(
                    _userCards.isEmpty
                        ? 'Add cards to your collection first'
                        : 'No cards match your search',
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredCards.length,
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];
                    final isSelected = _userCard?.id == card.id;
                    
                    return GestureDetector(
                      onTap: () => _selectCard(card),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected 
                              ? Border.all(color: Colors.blue, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Image.network(
                                  card.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                              loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                color: Colors.black54,
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Power: ${(card.price ?? 0).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
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
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildSelectingState() {
  // Replace the background image with a gradient
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.purple.shade900,
          Colors.indigo.shade900,
          Colors.blue.shade900,
        ],
      ),
    ),
    child: _isLoading 
      ? _buildLoadingView() 
      : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Battle stats card - use enhanced version
              _buildEnhancedStatsCard(),
              
              const SizedBox(height: 24),
              
              // Card selection area with glass morphism effect
              _buildCardSelectionArea(),
              
              const SizedBox(height: 24),
              
              // Battle history with improved styling
              _buildBattleHistorySection(),
            ],
          ),
        ),
  );
}

  Widget _buildEnhancedStatsCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900.withOpacity(0.7),
            Colors.purple.shade900.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: BattleStatsCard(
        wins: _wins,
        losses: _losses,
        draws: _draws,
      ),
    );
  }

Widget _buildCardSelectionArea() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with champion title and swap button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Champion',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                    ),
                    onPressed: _showCardSelection,
                    tooltip: 'Change Card',
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Card image and stats
              if (_userCard != null) ...[
                // Center the card
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Hero(
                          tag: 'card-${_userCard!.id}',
                          child: Container(
                            height: 260,
                            width: 190,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _getElementColor(_userCardStats?.element ?? 'normal').withOpacity(0.8),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              tween: Tween(begin: -0.02, end: 0.02),
                              builder: (context, value, child) {
                                return Transform(
                                  alignment: FractionalOffset.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(value)
                                    ..rotateX(value / 2),
                                  child: child,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _userCard!.imageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 260,
                                      width: 190,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          color: Colors.white38,
                                          size: 60,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Power display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Battle Power: ${(_userCardStats?.attackPower ?? 0).toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Card info
                _buildCardInfo(),
                
                const SizedBox(height: 24),
                
                // Battle button - THIS WAS MISSING
                _buildEnhancedBattleButton(),
              ]
              else ...[
                // Empty state for when no card is selected
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 60,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a card',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Choose card button
                _buildEnhancedBattleButton(),
              ],
              
              // Opponent card section
              if (_cpuCard != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'VERSUS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                
                // CPU card
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade800,
                          Colors.orange.shade800,
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.black,
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _cpuCard!.imageUrl,
                            height: 100,
                            width: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 100,
                                width: 70,
                                color: Colors.grey[800],
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white70,
                                    size: 30,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Center(
                  child: Text(
                    _cpuCard!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCardInfo() {
    if (_userCardStats == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        // Card name with stylish background
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black54,
                Colors.black38,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            _userCard!.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Card stats with improved visuals
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black54,
                Colors.black38,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildStatBar('Attack', _userCardStats!.attackPower, Colors.redAccent),
              const SizedBox(height: 10),
              _buildStatBar('Defense', _userCardStats!.defensePower, Colors.blueAccent),
              const SizedBox(height: 10),
              _buildStatBar('Special', _userCardStats!.specialPower, Colors.purpleAccent),
              const SizedBox(height: 10),
              _buildStatBar('Speed', _userCardStats!.speed, Colors.greenAccent),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Element badge and special ability
        Row(
          children: [
            // Element badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getElementColor(_userCardStats!.element),
                    _getElementColor(_userCardStats!.element).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getElementColor(_userCardStats!.element).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                _userCardStats!.element.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Special ability badge
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white10,
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _userCardStats!.specialAbility,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedBattleButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: _userCard != null 
              ? [Colors.red.shade700, Colors.deepOrange.shade700]
              : [Colors.grey.shade700, Colors.grey.shade800],
        ),
        boxShadow: _userCard != null ? [
          BoxShadow(
            color: Colors.red.shade700.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _userCard == null ? _loadUserCards : _startBattle,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _userCard == null ? Icons.add_circle : Icons.sports_kabaddi,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  _userCard == null ? 'Choose Card' : 'START BATTLE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBattleHistorySection() {
    if (_battleHistory.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Battles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        
        // Battle history items with slight spacing
        ..._battleHistory.take(3).map((result) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BattleHistoryItem(result: result),
        )),
      ],
    );
  }
  
  Widget _buildBattlingState() {
    if (_userCard == null || _cpuCard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return CardBattleAnimation(
      userCard: _userCard!,
      cpuCard: _cpuCard!,
      animationController: _animationController,
      userStats: _userCardStats,
      cpuStats: _cpuCardStats,
      onBattleComplete: _completeBattle,
    );
  }
  
  Widget _buildResultsState() {
    if (_battleHistory.isEmpty) {
      return const Center(child: Text('No battle results available'));
    }
    
    final result = _battleHistory.first;
    final isWin = result.result == 'win';
    final isDraw = result.result == 'draw';
    
    return AnimatedBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Result header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: isWin 
                    ? Colors.green 
                    : isDraw 
                        ? Colors.amber 
                        : Colors.red,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isWin 
                      ? 'VICTORY!' 
                      : isDraw 
                          ? 'DRAW!' 
                          : 'DEFEAT!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Cards comparison with consistent power labeling
            Row(
              children: [
                // Your card
                Expanded(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          result.userCard.imageUrl,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.userCard.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Update the battle points label for consistency
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isWin ? Colors.green.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Battle Points: ${result.userPoints.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isWin ? Colors.green : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // VS
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      child: const Center(
                        child: Text(
                          'VS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Opponent card
                Expanded(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          result.opponentCard.imageUrl,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.opponentCard.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Use the same label for consistency
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: !isWin && !isDraw ? Colors.red.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Battle Points: ${result.opponentPoints.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !isWin && !isDraw ? Colors.red : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Battle stats
            BattleStatsCard(
              wins: _wins,
              losses: _losses,
              draws: _draws,
            ),
            
            const SizedBox(height: 24),
            
            // Battle again button
            StyledButton(
              text: 'Battle Again',
              icon: Icons.replay,
              isWide: true,
              hasGlow: true,
              onPressed: _resetBattle,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your cards...'),
        ],
      ),
    );
  }
  
  Widget _buildStatBar(String label, double value, Color color) {
    // Scale the stats to a reasonable percentage (0-100%)
    final percentage = (value / 50).clamp(0.0, 1.0);
    
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
      default:
        return Colors.grey;
    }
  }
}
