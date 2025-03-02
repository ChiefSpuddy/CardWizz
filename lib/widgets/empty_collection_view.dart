import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import '../services/tcg_api_service.dart';
import '../models/tcg_card.dart';
import '../screens/card_details_screen.dart';
import 'package:provider/provider.dart';

class EmptyCollectionView extends StatefulWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData icon;
  final VoidCallback? onActionPressed;

  const EmptyCollectionView({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Search Cards',
    this.icon = Icons.style_outlined,
    this.onActionPressed,
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
  final int _maxDisplayedCards = 5;  // Increased from 3

  // Add a new animation controller for the button gradient
  late final AnimationController _gradientController;

  // Add controller for new confetti animation
  late final AnimationController _confettiController;

  // Add a second confetti controller for smooth transitions
  late final AnimationController _confettiController2;
  bool _useFirstController = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

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

    Future.delayed(Duration.zero, () => _titleController.forward());
    Future.delayed(const Duration(milliseconds: 300), () => _descriptionController.forward());
    Future.delayed(const Duration(milliseconds: 600), () => _buttonController.forward());

    for (int i = 0; i < _featureControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 400 + (i * 200)), () {
        if (mounted) _featureControllers[i].forward();
      });
    }

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: false);

    _cardRotation = CurvedAnimation(
      parent: _cardsController,
      curve: Curves.linear,
    );

    // Initialize the gradient animation controller
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Initialize confetti controller
    _confettiController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 8), // Longer duration for smoother animation
    );

    // Initialize secondary confetti controller for smooth looping
    _confettiController2 = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 8), // Match the first controller's duration
    );
    
    // Start confetti after button appears, and make it repeat
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _confettiController.forward();
        
        // Start second controller midway through first controller's animation
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            _confettiController2.forward();
          }
        });
        
        // Set up continuous looping with overlapping animations
        _confettiController.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _confettiController.reset();
                _confettiController.forward();
              }
            });
          }
        });
        
        _confettiController2.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _confettiController2.reset();
                _confettiController2.forward();
              }
            });
          }
        });
      }
    });

    _fetchPreviewCards();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _buttonController.dispose();
    for (final controller in _featureControllers) {
      controller.dispose();
    }
    _cardsController.dispose();
    _gradientController.dispose();
    _confettiController.dispose();
    _confettiController2.dispose();
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
        pageSize: 15,  // Increased from 10
      );

      if (mounted) {
        setState(() {
          _previewCards.clear();
          _previewCards.addAll((response['data'] as List? ?? []).cast<Map<String, dynamic>>());
          _isLoadingCards = false;
        });
      }
    } catch (e) {
      print('Error loading preview cards: $e');
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

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/search',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.07,
            child: Lottie.asset(
              'assets/animations/background.json',
              fit: BoxFit.cover,
              controller: _animationController,
              options: LottieOptions(enableMergePaths: false),
            ),
          ),
        ),
        
        if (_previewCards.isNotEmpty)
          ..._buildOptimizedFloatingCards(),
        
        // Improved confetti overlay with continuous animation
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                // Continuously running first confetti layer
                AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    return _buildConfettiOverlay(
                      _confettiController.value,
                      random: math.Random(42),
                      opacity: 0.65,
                    );
                  },
                ),
                
                // Continuously running second confetti layer with different seed
                AnimatedBuilder(
                  animation: _confettiController2,
                  builder: (context, child) {
                    return _buildConfettiOverlay(
                      _confettiController2.value,
                      random: math.Random(24),
                      opacity: 0.65,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Adjust vertical spacing based on screen size
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Main icon - slightly smaller on small screens
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
                  child: Icon(
                    widget.icon,
                    size: isSmallScreen ? 36 : 40,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Title animation - unchanged
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith( // Changed from headlineMedium
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 2 : 4),
                
                // Description animation - unchanged
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith( // Changed from bodyLarge
                      color: colorScheme.onSurface.withOpacity(0.7),
                      height: 1.3, // Reduced line height
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Card preview - optimize for small screens
                _buildCompactCardPreview(smallScreen: isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 10 : 16),
                
                // Features list - optimize for small screens
                _buildEnhancedFeaturesList(context, smallScreen: isSmallScreen),
                
                SizedBox(height: isSmallScreen ? 10 : 16),
                
                // Button - unchanged
                _buildAnimatedButton(),
                
                // Bottom padding - smaller on small screens
                SizedBox(height: isSmallScreen ? 16 : 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptimizedFloatingCards() {
    final screenSize = MediaQuery.of(context).size;
    final random = math.Random(42);
    
    return List.generate(
      math.min(5, _previewCards.length), 
      (index) {
        double top = random.nextDouble() * screenSize.height * 0.6;
        double left;
        
        if (index % 2 == 0) {
          left = random.nextDouble() * screenSize.width * 0.15;
        } else {
          left = screenSize.width * 0.85 - (random.nextDouble() * screenSize.width * 0.15);
        }
        
        final size = 80.0 + random.nextDouble() * 40;
        final baseRotation = (index % 2 == 0) ? -0.2 : 0.2;
        final card = _previewCards[index];
        final imageUrl = card['images']?['small'];
        
        if (imageUrl == null) return const SizedBox.shrink();
        
        return Positioned(
          top: top,
          left: left,
          child: AnimatedBuilder(
            animation: _cardRotation,
            builder: (context, child) {
              final wobble = math.sin(_cardRotation.value * math.pi * 2) * 0.05;
              return Transform.rotate(
                angle: baseRotation + wobble,
                child: child,
              );
            },
            child: Container(
              width: size,
              height: size * 1.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.2),
                  errorBuilder: (context, error, stackTrace) => 
                      Container(color: Colors.grey.withOpacity(0.1)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCardPreview({bool smallScreen = false}) {
    if (_isLoadingCards) {
      return const SizedBox(
        height: 120, // Reduced from 140
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
                  fontSize: 14, // Reduced text size
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Text(
              'Tap to explore →',
              style: TextStyle(
                fontSize: 11, // Smaller text
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6), // Reduced from 8
        SizedBox(
          height: smallScreen ? 100 : 120, // Reduce height on small screens
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: math.min(_maxDisplayedCards, _previewCards.length),
            itemBuilder: (context, index) {
              final card = _previewCards[index];
              final imageUrl = card['images']?['small'];
              if (imageUrl == null) return const SizedBox.shrink();

              final previewCard = TcgCard(
                id: card['id'] ?? '',
                name: card['name'] ?? '',
                imageUrl: imageUrl,
                largeImageUrl: card['images']?['large'] ?? imageUrl,
                set: TcgSet(id: '', name: card['set']?['name'] ?? ''),
                price: card['cardmarket']?['prices']?['averageSellPrice'],
              );

              return Padding(
                padding: const EdgeInsets.only(right: 6.0), // Reduced from 8.0
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailsScreen(
                          card: previewCard,
                          // Change this to use a unique tag for each card
                          heroContext: 'empty_preview_index_$index',
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    // Change this to use a unique tag for each card
                    tag: 'empty_preview_index_$index',
                    child: Container(
                      width: smallScreen ? 75 : 85, // Reduce width on small screens
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              height: smallScreen ? 85 : 100, // Reduce height on small screens
                              width: smallScreen ? 75 : 85, // Match container width
                            ),
                          ),
                          if (previewCard.price != null)
                            Padding(
                              padding: EdgeInsets.only(top: smallScreen ? 1 : 2),
                              child: Text(
                                '\$${previewCard.price!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: smallScreen ? 9 : 10, // Smaller text on small screens
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

  // Replace _buildCompactFeaturesList with this enhanced version
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
                    // Increase opacity for better contrast
                    features[i].$4[0].withOpacity(0.25),
                    features[i].$4[1].withOpacity(0.3),
                  ],
                ),
                border: Border.all(
                  color: features[i].$4[0].withOpacity(0.5), // More visible border
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: features[i].$4[0].withOpacity(0.2), // More visible shadow
                    blurRadius: smallScreen ? 6 : 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated icon container
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
                            color: features[i].$4[0].withOpacity(0.9), // More visible text
                            fontSize: smallScreen ? 13 : 14,
                          ),
                        ),
                        SizedBox(height: smallScreen ? 2 : 4),
                        Text(
                          smallScreen
                              ? _getShortDescription(features[i].$2) // Use shorter text on small screens
                              : features[i].$2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // More visible text
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
        height: 56, // Reduced from 60
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
                    blurRadius: 10, // Reduced from 12
                    offset: const Offset(0, 5), // Reduced from 6
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(context),
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24, // Reduced from 26
                ),
                label: Text(
                  widget.buttonText,
                  style: const TextStyle(
                    fontSize: 16, // Reduced from 18
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Reduced from 24,16
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Improved confetti animation
  Widget _buildConfettiOverlay(
    double animation, {
    required math.Random random,
    double opacity = 0.65,
  }) {
    if (animation < 0.01) return const SizedBox.shrink();
    
    final screenSize = MediaQuery.of(context).size;
    
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: ConfettiPainter(
          animation: animation,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.tertiary,
            Colors.pink,
            Colors.purple,
            Colors.yellow,
            Colors.orange,
          ],
          random: random,
          count: 25, // Reduced from 30 for better performance
          screenWidth: screenSize.width,
        ),
        size: Size(screenSize.width, screenSize.height),
      ),
    );
  }

  // Helper method to get shortened descriptions for small screens
  String _getShortDescription(String fullDescription) {
    if (fullDescription.contains(',')) {
      return fullDescription.split(',')[0] + '.';
    }
    if (fullDescription.length > 50) {
      return fullDescription.substring(0, 50) + '...';
    }
    return fullDescription;
  }
}

// Improved confetti painter class
class ConfettiPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;
  final math.Random random;
  final int count;
  final double screenWidth;
  final List<_ConfettiParticle> _particles = [];
  
  ConfettiPainter({
    required this.animation,
    required this.colors,
    required this.random,
    required this.count,
    required this.screenWidth,  // Add screen width parameter
  }) {
    if (_particles.isEmpty) {
      for (int i = 0; i < count; i++) {
        // Distribute particles evenly across the full screen width
        _particles.add(_ConfettiParticle(
          color: colors[random.nextInt(colors.length)],
          position: Offset(
            random.nextDouble() * screenWidth, // Use full screen width
            -50 - random.nextDouble() * 300, // Stagger starting positions
          ),
          size: 3 + random.nextDouble() * 6,
          speed: 150 + random.nextDouble() * 200,
          // Vary rotation more for natural movement
          rotation: random.nextDouble() * 2 * math.pi,
          rotationSpeed: (random.nextDouble() * 2 - 1) * 0.6,
          // Add horizontal drift for more natural movement
          horizontalDrift: (random.nextDouble() * 2 - 1) * 50,
        ));
      }
    }
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      // Use sine wave for vertical movement to create a more natural flow effect
      final totalDistance = particle.speed * animation;
      final verticalPosition = (particle.position.dy + totalDistance) % (size.height + 200);
      
      // Add wobble movement based on sine waves with different frequencies
      final horizontalWobble = math.sin(animation * math.pi * 2 + particle.rotation) * 
                              (particle.horizontalDrift * 0.8);
      final verticalWobble = math.cos(animation * math.pi + particle.rotation * 2) * 5.0;
      
      final position = Offset(
        (particle.position.dx + horizontalWobble) % size.width,
        verticalPosition + verticalWobble,
      );
      
      // Only draw particles that are in view
      if (position.dy > -50 && position.dy < size.height + 50) {
        // Use a slightly transparent paint for better visuals
        final paint = Paint()..color = particle.color.withOpacity(0.65);
        
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(particle.rotation + particle.rotationSpeed * animation);
        
        // Draw different confetti shapes with smoother edges
        if (random.nextInt(3) == 0) {
          // Rectangle confetti
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: particle.size * 0.8,
                height: particle.size * 1.3,
              ),
              Radius.circular(1.0), // Slightly rounded corners
            ),
            paint,
          );
        } else if (random.nextInt(3) == 1) {
          // Circle confetti
          canvas.drawCircle(
            Offset.zero,
            particle.size / 2,
            paint,
          );
        } else {
          // Diamond confetti
          final path = Path()
            ..moveTo(0, -particle.size / 2)
            ..lineTo(particle.size / 2, 0)
            ..lineTo(0, particle.size / 2)
            ..lineTo(-particle.size / 2, 0)
            ..close();
          canvas.drawPath(path, paint);
        }
        
        canvas.restore();
      }
    }
  }
  
  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true; // Always repaint for continuous animation
}

class _ConfettiParticle {
  final Color color;
  final Offset position;
  final double size;
  final double speed;
  final double rotation;
  final double rotationSpeed;
  final double horizontalDrift;  // Add this property
  
  _ConfettiParticle({
    required this.color,
    required this.position,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.horizontalDrift,  // Add this parameter
  });
}
