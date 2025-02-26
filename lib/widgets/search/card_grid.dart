import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tcg_card.dart';
import '../../screens/card_details_screen.dart';
import '../../constants/app_colors.dart';
import 'dart:math' as math;

class CardSearchGrid extends StatefulWidget {
  final List<TcgCard> cards;
  final Map<String, Image> imageCache;
  final Function(String) loadImage;
  final Set<String> loadingRequestedUrls;

  const CardSearchGrid({
    Key? key,
    required this.cards,
    required this.imageCache,
    required this.loadImage,
    required this.loadingRequestedUrls,
  }) : super(key: key);

  @override
  State<CardSearchGrid> createState() => _CardSearchGridState();
}

class _CardSearchGridState extends State<CardSearchGrid> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  final List<AnimationController> _cardControllers = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    _animationController.forward();
    
    // Create individual controllers for hover effect
    for (int i = 0; i < widget.cards.length; i++) {
      _cardControllers.add(AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
        value: 0,
      ));
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  void didUpdateWidget(CardSearchGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controllers if cards change
    if (oldWidget.cards != widget.cards) {
      for (final controller in _cardControllers) {
        controller.dispose();
      }
      _cardControllers.clear();
      
      for (int i = 0; i < widget.cards.length; i++) {
        _cardControllers.add(AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
          value: 0,
        ));
      }
      
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7, // Taller cards look better
          crossAxisSpacing: 12,
          mainAxisSpacing: 20, // More space between rows
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Staggered animation based on position
            final delay = (index % 9) * 50;
            
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  delay / 1000, // Start delay based on index
                  0.5 + (delay / 1000), // End point based on index
                  curve: Curves.easeOutQuint,
                ),
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    delay / 1000, // Start delay based on index
                    0.5 + (delay / 1000), // End point based on index
                    curve: Curves.easeOut,
                  ),
                ),
                child: _buildCardItem(context, widget.cards[index], index),
              ),
            );
          },
          childCount: widget.cards.length,
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, TcgCard card, int index) {
    final String url = card.imageUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Request image loading if needed
    if (!widget.loadingRequestedUrls.contains(url) && 
        !widget.imageCache.containsKey(url)) {
      widget.loadImage(url);
    }

    final cachedImage = widget.imageCache[url];
    final hasPrice = card.price != null && card.price! > 0;
    
    // Hover animation
    return MouseRegion(
      onEnter: (_) => _cardControllers[index].forward(),
      onExit: (_) => _cardControllers[index].reverse(),
      child: AnimatedBuilder(
        animation: _cardControllers[index],
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_cardControllers[index].value * 0.05),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 + (_cardControllers[index].value * 0.2)),
                    blurRadius: 10 + (_cardControllers[index].value * 10),
                    offset: const Offset(0, 5),
                    spreadRadius: _cardControllers[index].value * 5,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            // Add haptic feedback for a premium feel
            HapticFeedback.lightImpact();
            
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) {
                  return FadeTransition(
                    opacity: animation,
                    child: CardDetailsScreen(
                      card: card,
                      heroContext: 'search',
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: Hero(
            tag: 'card_${card.id}_search',
            flightShuttleBuilder: (_, animation, direction, ___, ____) {
              final isForward = direction == HeroFlightDirection.push;
              
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isForward
                      ? 1.0 + (animation.value * 0.15) // Grow when pushing
                      : 1.15 - (animation.value * 0.15), // Shrink when popping
                    child: cachedImage ?? const SizedBox(),
                  );
                },
              );
            },
            child: Stack(
              children: [
                // Card image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    child: cachedImage ?? Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Card details overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      card.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Price badge
                if (hasPrice)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getPriceGradient(card.price!),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '€${card.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                
                // Rarity indicator
                if (card.rarity != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _getRarityGradient(card.rarity!),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _getRarityIcon(card.rarity!),
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  List<Color> _getPriceGradient(double price) {
    if (price > 100) {
      return const [Color(0xFFFF1744), Color(0xFFFF5252)]; // High value
    } else if (price > 50) {
      return const [Color(0xFFFF9100), Color(0xFFFFAB40)]; // Medium-high value
    } else if (price > 10) {
      return const [Color(0xFFFFD600), Color(0xFFFFE57F)]; // Medium value
    } else {
      return const [Color(0xFF00C853), Color(0xFF69F0AE)]; // Low value
    }
  }
  
  List<Color> _getRarityGradient(String rarity) {
    final rarityLower = rarity.toLowerCase();
    
    if (rarityLower.contains('hyper') || rarityLower.contains('secret')) {
      return const [Color(0xFF9C27B0), Color(0xFFBA68C8)]; // Purple for hyper/secret rare
    } else if (rarityLower.contains('ultra')) {
      return const [Color(0xFFF57C00), Color(0xFFFFB74D)]; // Orange for ultra rare
    } else if (rarityLower.contains('rare') && !rarityLower.contains('ultra')) {
      return const [Color(0xFFFFD700), Color(0xFFFFF176)]; // Gold for rare
    } else if (rarityLower.contains('uncommon')) {
      return const [Color(0xFF039BE5), Color(0xFF81D4FA)]; // Blue for uncommon
    } else {
      return const [Color(0xFF9E9E9E), Color(0xFFE0E0E0)]; // Grey for common
    }
  }
  
  IconData _getRarityIcon(String rarity) {
    final rarityLower = rarity.toLowerCase();
    
    if (rarityLower.contains('hyper') || rarityLower.contains('secret')) {
      return Icons.auto_awesome;
    } else if (rarityLower.contains('ultra')) {
      return Icons.star;
    } else if (rarityLower.contains('rare') && !rarityLower.contains('ultra')) {
      return Icons.star_border;
    } else if (rarityLower.contains('uncommon')) {
      return Icons.star_half;
    } else {
      return Icons.circle;
    }
  }
}
