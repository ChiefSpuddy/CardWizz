import '../services/logging_service.dart';
import 'package:flutter/material.dart';
import '../services/tcg_api_service.dart';
import '../screens/card_details_screen.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;  // Add this import for math.min
import '../models/tcg_card.dart';  // Add this import for TcgCard
import '../models/tcg_set.dart' as models;   // Import with alias

class EmptyCollectionView extends StatefulWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final bool showButton;
  final String uniqueId;
  final bool showHeader;
  final bool showAppBar; // Add this parameter

  const EmptyCollectionView({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Search Cards',
    this.icon = Icons.style_outlined,
    this.onActionPressed,
    this.showButton = true,
    this.uniqueId = '',
    this.showHeader = true,
    this.showAppBar = false, // Default to false to be consistent with SignInView
  });

  @override
  State<EmptyCollectionView> createState() => _EmptyCollectionViewState();
}

class _EmptyCollectionViewState extends State<EmptyCollectionView> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _titleController;
  late final AnimationController _descriptionController;
  late final AnimationController _buttonController;
  late final List<AnimationController> _featureControllers;
  late final AnimationController _cardsController;
  late final Animation<double> _cardRotation;
  final List<Map<String, dynamic>> _previewCards = [];
  bool _isLoadingCards = true;
  final int _maxDisplayedCards = 5;
  
  // Add a new animation controller for the button gradient
  late final AnimationController _gradientController;
  
  late final AnimationController _scaleController;
  late final AnimationController _bounceController;
  bool _isDisposed = false;

  // Ensure we have a unique ID for each instance
  final String _uniqueId = DateTime.now().microsecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _descriptionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _featureControllers = List.generate(3, (i) => 
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )
    );

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    _cardRotation = CurvedAnimation(
      parent: _cardsController,
      curve: Curves.linear,
    );

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Use a single post frame callback to start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      
      // Start immediate animations
      _animationController.repeat(reverse: true);
      _cardsController.repeat(reverse: false);
      _gradientController.repeat();
      
      // Delayed animations with safety checks
      Future<void> startAnimation(AnimationController controller, {Duration delay = Duration.zero}) async {
        await Future.delayed(delay);
        if (!_isDisposed && mounted) {
          controller.forward();
        }
      }

      // Schedule animations
      startAnimation(_titleController);
      startAnimation(_descriptionController, delay: const Duration(milliseconds: 300));
      startAnimation(_buttonController, delay: const Duration(milliseconds: 600));
      
      // Feature animations
      for (int i = 0; i < _featureControllers.length; i++) {
        startAnimation(
          _featureControllers[i],
          delay: Duration(milliseconds: 400 + (i * 200)),
        );
      }
      
      // Scale and bounce animations
      startAnimation(_scaleController);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!_isDisposed && mounted) {
          _bounceController.repeat(reverse: true);
        }
      });
    });

    _fetchPreviewCards();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _buttonController.dispose();
    for (final controller in _featureControllers) {
      controller.dispose();
    }
    _cardsController.dispose();
    _gradientController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _fetchPreviewCards() async {
    if (!mounted) return;
    
    try {
      final apiService = TcgApiService();
      final response = await apiService.searchCards(
        query: 'rarity:"Special Illustration Rare" OR rarity:"Illustration Rare" OR rarity:"Secret Rare" OR rarity:"Alt Art" OR rarity:"Alternative Art" OR rarity:"Character Rare" OR rarity:"Full Art"',
        orderBy: 'cardmarket.prices.averageSellPrice', 
        orderByDesc: true,
        pageSize: 15,
      );

      if (mounted) {
        setState(() {
          _previewCards.clear();
          _previewCards.addAll((response['data'] as List? ?? []).cast<Map<String, dynamic>>());
          _isLoadingCards = false;
        });
      }
    } catch (e) {
      LoggingService.debug('Error loading preview cards: $e');
      if (mounted) {
        setState(() => _isLoadingCards = false);
      }
    }
  }

  void _handleAction(BuildContext context) {
    if (widget.onActionPressed != null) {
      widget.onActionPressed!();
      return;
    }

    // Simply navigate without showing any toasts
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/search',
      (route) => false,
    );
  }

  String _getShortDescription(String fullDescription) {
    if (fullDescription.contains(',')) {
      return fullDescription.split(',')[0] + '.';
    }
    if (fullDescription.length > 50) {
      return fullDescription.substring(0, 50) + '...';
    }
    return fullDescription;
  }

  Widget _buildCompactCardPreview({bool smallScreen = false}) {
    if (_isLoadingCards) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_previewCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Special Cards Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Text(
              'Tap to explore →',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: smallScreen ? 100 : 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: math.min(_maxDisplayedCards, _previewCards.length),
            itemBuilder: (context, index) {
              final card = _previewCards[index];
              final imageUrl = card['images']?['small'];
              if (imageUrl == null || imageUrl.isEmpty) return const SizedBox.shrink();

              final previewCard = TcgCard(
                id: card['id'] ?? '',
                name: card['name'] ?? '',
                imageUrl: imageUrl,
                largeImageUrl: card['images']?['large'] ?? imageUrl,
                set: models.TcgSet(id: '', name: card['set']?['name'] ?? ''), // Use aliased version
                price: card['cardmarket']?['prices']?['averageSellPrice'],
              );

              // Change this Hero tag to use our unique instance ID
              final uniqueHeroTag = 'empty_preview_${widget.uniqueId}_${_uniqueId}_$index';

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailsScreen(
                          card: previewCard,
                          heroContext: uniqueHeroTag,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: uniqueHeroTag,
                    child: Container(
                      width: smallScreen ? 75 : 85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              height: smallScreen ? 85 : 100,
                              width: smallScreen ? 75 : 85,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: smallScreen ? 85 : 100,
                                  width: smallScreen ? 75 : 85,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                );
                              },
                            ) : Container(
                              height: smallScreen ? 85 : 100,
                              width: smallScreen ? 75 : 85,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                          if (previewCard.price != null)
                            Padding(
                              padding: EdgeInsets.only(top: smallScreen ? 1 : 2),
                              child: Text(
                                '\$${previewCard.price!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: smallScreen ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
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

  Widget _buildEnhancedFeaturesList(BuildContext context, {bool smallScreen = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final features = [
      (
        'Track Collection',
        'Keep inventory of all your cards with prices, track trends and investment performance.',
        Icons.folder_special,
        [colorScheme.primary, colorScheme.primaryContainer],
      ),
      (
        'Live Market Prices',
        'Stay updated with real-time values from multiple marketplaces.',
        Icons.trending_up,
        [colorScheme.secondary, colorScheme.secondaryContainer],
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < features.length; i++)
          AnimatedBuilder(
            animation: _featureControllers[i],
            builder: (context, child) {
              return Opacity(
                opacity: _featureControllers[i].value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - _featureControllers[i].value), 0),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: smallScreen ? 6 : 10),
              padding: EdgeInsets.all(smallScreen ? 10 : 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    features[i].$4[0].withOpacity(0.25),
                    features[i].$4[1].withOpacity(0.3),
                  ],
                ),
                border: Border.all(
                  color: features[i].$4[0].withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: features[i].$4[0].withOpacity(0.2),
                    blurRadius: smallScreen ? 6 : 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: smallScreen ? 36 : 42,
                      height: smallScreen ? 36 : 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            features[i].$4[0],
                            features[i].$4[1],
                          ],
                        ),
                        borderRadius: BorderRadius.circular(smallScreen ? 8 : 10),
                        boxShadow: [
                          BoxShadow(
                            color: features[i].$4[0].withOpacity(0.4),
                            blurRadius: smallScreen ? 5 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        features[i].$3,
                        color: Colors.white,
                        size: smallScreen ? 18 : 22,
                      ),
                    ),
                  ),
                  SizedBox(width: smallScreen ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          features[i].$1,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: features[i].$4[0].withOpacity(0.9),
                            fontSize: smallScreen ? 13 : 14,
                          ),
                        ),
                        SizedBox(height: smallScreen ? 2 : 4),
                        Text(
                          smallScreen
                              ? _getShortDescription(features[i].$2)
                              : features[i].$2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            height: smallScreen ? 1.1 : 1.3,
                            fontSize: smallScreen ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Opacity(
          opacity: _buttonController.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _buttonController.value)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    0,
                    0.25 + 0.3 * _gradientController.value,
                    0.5 + 0.2 * _gradientController.value,
                    0.75 + 0.1 * _gradientController.value,
                    1,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(context),
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
                label: Text(
                  widget.buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    final heroTag = 'empty_view${widget.uniqueId.isNotEmpty ? "_${widget.uniqueId}" : "_${DateTime.now().millisecondsSinceEpoch}"}';

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  
                  Container(
                    width: isSmallScreen ? 70 : 80,
                    height: isSmallScreen ? 70 : 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withOpacity(0.7),
                          colorScheme.secondary.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: heroTag,
                      child: Icon(
                        widget.icon,
                        size: isSmallScreen ? 36 : 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  AnimatedBuilder(
                    animation: _titleController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _titleController.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _titleController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  
                  AnimatedBuilder(
                    animation: _descriptionController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _descriptionController.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _descriptionController.value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  _buildCompactCardPreview(smallScreen: isSmallScreen),
                  
                  SizedBox(height: isSmallScreen ? 10 : 16),
                  
                  _buildEnhancedFeaturesList(context, smallScreen: isSmallScreen),
                  
                  SizedBox(height: isSmallScreen ? 10 : 16),
                  
                  _buildAnimatedButton(),
                  
                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
