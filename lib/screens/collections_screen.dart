import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/empty_collection_view.dart';
import '../l10n/app_localizations.dart';  
import '../services/storage_service.dart';
import '../services/collection_service.dart';
import '../models/tcg_card.dart';
import '../models/custom_collection.dart';
import '../widgets/collection_grid.dart';
import '../widgets/custom_collections_grid.dart';
import '../widgets/create_collection_sheet.dart';
import '../widgets/create_binder_dialog.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'custom_collection_detail_screen.dart';
import '../widgets/animated_background.dart';
import '../constants/card_styles.dart';
import '../widgets/app_drawer.dart';
import '../providers/currency_provider.dart';
import '../widgets/sign_in_view.dart';
import '../providers/app_state.dart';
import '../providers/sort_provider.dart';
import '../constants/layout.dart';
import '../services/purchase_service.dart'; // Add this missing import
import 'dart:math';
import '../widgets/standard_app_bar.dart';

class CollectionsScreen extends StatefulWidget {
  final bool _showEmptyState;
  
  const CollectionsScreen({
    super.key,
    bool showEmptyState = true,
  }) : _showEmptyState = showEmptyState;

  @override
  State<CollectionsScreen> createState() => CollectionsScreenState();
}

class CollectionsScreenState extends State<CollectionsScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  bool _showCustomCollections = false;
  late bool _pageViewReady = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Add this to track multiselect mode
  bool _isMultiselectActive = false;

  // Animation controllers
  late AnimationController _fadeInController;
  late AnimationController _slideController;
  late AnimationController _valueController;
  late AnimationController _toggleController;
  
  // Particle system for background effects
  final List<_CollectionParticle> _particles = [];
  final Random _random = Random();

  // Add properties for optimization
  bool _isScrolling = false;
  Timer? _debounceTimer;
  
  // Reduce particle count for better performance
  final int _maxParticles = 8; // Reduced from 20
  bool _animateParticles = true;

  // Add a flag to control debug output
  static const bool _enableDebugLogs = false;  // Set to false to disable verbose logging
  
  // Add helper method for controlled debug logging
  void _debugLog(String message) {
    if (_enableDebugLogs) {
      print(message);
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _valueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _toggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _pageViewReady = true);
      _fadeInController.forward();
      _slideController.forward();
      _valueController.forward();
      _toggleController.forward();
      
      // Initialize background particles with fewer particles
      _initializeParticles();
    });
  }

  void _initializeParticles() {
    // Create particles with reduced count
    _particles.clear();
    for (int i = 0; i < _maxParticles; i++) {
      _particles.add(
        _CollectionParticle(
          position: Offset(
            _random.nextDouble() * MediaQuery.of(context).size.width,
            _random.nextDouble() * MediaQuery.of(context).size.height,
          ),
          size: 2 + _random.nextDouble() * 3, // Slightly smaller particles
          speed: 0.1 + _random.nextDouble() * 0.2, // Slower speed
          angle: _random.nextDouble() * 2 * pi,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _slideController.dispose();
    _valueController.dispose();
    _toggleController.dispose();
    _pageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _showCustomCollections = page == 1;
    });
  }

  bool get showCustomCollections => _showCustomCollections;
  set showCustomCollections(bool value) {
    setState(() {
      _showCustomCollections = value;
    });
  }

  // Add this method to update multiselect state from child widgets
  void setMultiselectActive(bool active) {
    if (_isMultiselectActive != active) {
      _debugLog('Setting multiselect active: $active'); // Controlled debug log
      setState(() {
        _isMultiselectActive = active;
      });
    }
  }

  // Improved toggle with animations
  Widget _buildAnimatedToggle() {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: _toggleController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _toggleController.value),
          child: Opacity(
            opacity: _toggleController.value,
            child: Container(
              height: 40, // Reduced from 48 to 40
              margin: const EdgeInsets.symmetric(horizontal: 20), // Increased horizontal margin from 16 to 20
              decoration: BoxDecoration(
                color: isDark 
                    ? colorScheme.surfaceVariant.withOpacity(0.3) 
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(20), // Changed from 24 to 20
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, // Reduced from 10 to 8
                    offset: const Offset(0, 3), // Reduced from 4 to 3
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_pageController.hasClients) {
                          _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: !_showCustomCollections
                              ? LinearGradient(
                                  colors: isDark ? [
                                    colorScheme.primary.withOpacity(0.8),
                                    colorScheme.primary,
                                  ] : [
                                    colorScheme.primary.withOpacity(0.9),
                                    colorScheme.primary,
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(20), // Changed from 24 to 20
                          boxShadow: !_showCustomCollections
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.style_outlined,
                                size: 16, // Reduced from 18 to 16
                                color: !_showCustomCollections
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant.withOpacity(0.8),
                              ),
                              const SizedBox(width: 6), // Reduced from 8 to 6
                              Text(
                                localizations.translate('main'),
                                style: TextStyle(
                                  fontSize: 13, // Reduced from 14 to 13
                                  fontWeight: FontWeight.w600,
                                  color: !_showCustomCollections
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_pageController.hasClients) {
                          _pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: _showCustomCollections
                              ? LinearGradient(
                                  colors: isDark ? [
                                    colorScheme.primary.withOpacity(0.8),
                                    colorScheme.primary,
                                  ] : [
                                    colorScheme.primary.withOpacity(0.9),
                                    colorScheme.primary,
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(20), // Changed from 24 to 20
                          boxShadow: _showCustomCollections
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.collections_bookmark_outlined,
                                size: 16, // Reduced from 18 to 16
                                color: _showCustomCollections
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant.withOpacity(0.8),
                              ),
                              const SizedBox(width: 6), // Reduced from 8 to 6
                              Text(
                                localizations.translate('binders'),
                                style: TextStyle(
                                  fontSize: 13, // Reduced from 14 to 13
                                  fontWeight: FontWeight.w600,
                                  color: _showCustomCollections
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // New animated value tracker card that shows collection value
  Widget _buildValueTrackerCard(List<TcgCard> cards, CurrencyProvider currencyProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
    
    return FadeTransition(
      opacity: _fadeInController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_slideController),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0), // Changed from 16 to 20
          child: InkWell(
            onTap: () {
              // Navigate to analytics page on tap
              final homeState = context.findAncestorStateOfType<HomeScreenState>();
              if (homeState != null) {
                homeState.setSelectedIndex(3); // Index for analytics tab
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 56, // Much shorter height
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark 
                      ? colorScheme.surfaceVariant.withOpacity(0.4)
                      : colorScheme.surface,
                    isDark 
                      ? colorScheme.surface.withOpacity(0.3)
                      : colorScheme.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Portfolio value with animation
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Collection Value',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        _valueController.value < 1.0
                          ? Text(
                              currencyProvider.formatValue(totalValue),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            )
                          : TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              tween: Tween(begin: 0, end: totalValue),
                              builder: (context, value, child) => Text(
                                currencyProvider.formatValue(value),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${cards.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.style_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to count unique sets
  int _countUniqueSets(List<TcgCard> cards) {
    final sets = <String>{};
    for (final card in cards) {
      if (card.setName != null) {
        sets.add(card.setName!);
      }
    }
    return sets.length;
  }

  // Add this method inside the class, before it's used in _buildSetDistribution
  List<MapEntry<String, int>> _getSetDistribution(List<TcgCard> cards) {
    // Group cards by set
    final setMap = <String, int>{};
    for (final card in cards) {
      final set = card.setName ?? 'Unknown Set';
      setMap[set] = (setMap[set] ?? 0) + 1;
    }

    // Sort sets by card count
    final sortedSets = setMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSets;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = context.watch<CurrencyProvider>();
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    final colorScheme = Theme.of(context).colorScheme;
    final purchaseService = context.watch<PurchaseService>(); // Added for use in actions
    
    // Replace debug print with controlled debug log
    _debugLog('Building CollectionsScreen, multiselect active: $_isMultiselectActive');

    return Scaffold(
      key: _scaffoldKey,
      
      // Use the static method to conditionally create appBar
      appBar: StandardAppBar.createIfSignedIn(
        context,
        transparent: true,
        elevation: 0,
        actions: isSignedIn ? [
          // Only show action buttons if signed in
          if (_isMultiselectActive)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Handle delete action for multiselect
                // This is a placeholder - implement your action
                print('Delete selected items');
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () => _showSortMenu(context),
              tooltip: 'Sort',
            ),
        ] : null,
      ),
      
      drawer: const AppDrawer(),
      
      // Main content with gradient at top for better app bar integration
      body: !isSignedIn
          ? const SignInView()
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Only animate particles when not scrolling
                if (notification is ScrollStartNotification && _animateParticles) {
                  setState(() => _animateParticles = false);
                } else if (notification is ScrollEndNotification && !_animateParticles) {
                  // Add small delay before re-enabling animations
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() => _animateParticles = true);
                    }
                  });
                }
                return false;
              },
              child: Stack(
                children: [
                  // Background effects
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _CollectionBackgroundPainter(
                          particles: _particles,
                          isDark: isDark,
                          primaryColor: colorScheme.primary,
                          animate: _animateParticles,
                        ),
                      ),
                    ),
                  ),
                  
                  // Enhanced gradient overlay that extends behind app bar
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            // Darker at top to ensure app bar text visibility
                            colorScheme.background.withOpacity(0.95),
                            colorScheme.background.withOpacity(0.85),
                            colorScheme.background.withOpacity(0.8),
                            colorScheme.background,
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8],
                        ),
                      ),
                    ),
                  ),
                  
                  // Main content area
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        
                        // Collection stats and value tracker
                        StreamBuilder<List<TcgCard>>(
                          stream: Provider.of<StorageService>(context).watchCards(),
                          builder: (context, snapshot) {
                            final cards = snapshot.data ?? [];
                            
                            // Only show the toggle and stats when there are cards
                            if (cards.isEmpty) {
                              return const Expanded(
                                child: EmptyCollectionView(
                                  title: 'Start Your Collection',
                                  message: 'Add cards to build your collection',
                                  buttonText: 'Browse Cards',
                                  icon: Icons.add_circle_outline,
                                ),
                              );
                            }
                            
                            // Show the stats card if there are cards
                            return Expanded(  // Add Expanded here to provide bounded height
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildValueTrackerCard(cards, currencyProvider),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Only show the toggle when we have cards
                                  _buildAnimatedToggle(),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Wrap PageView in Expanded to ensure it gets a definite size
                                  Expanded(
                                    child: _pageViewReady 
                                      ? AnimatedOpacity(
                                          duration: const Duration(milliseconds: 500),
                                          opacity: _fadeInController.value,
                                          child: PageView(
                                            controller: _pageController,
                                            onPageChanged: _onPageChanged,
                                            physics: const ClampingScrollPhysics(),
                                            children: [
                                              // Pass callbacks to both child widgets
                                              CollectionGrid(
                                                key: const PageStorageKey('main_collection'),
                                                onMultiselectChange: setMultiselectActive,
                                              ),
                                              CustomCollectionsGrid(
                                                key: const PageStorageKey('custom_collections'),
                                                onMultiselectChange: setMultiselectActive,
                                              ),
                                            ],
                                          ),
                                        )
                                      : const Center(
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      
      // Only show FAB when not in multiselect mode AND collection is not empty
      floatingActionButton: isSignedIn && !_isMultiselectActive
          ? StreamBuilder<List<TcgCard>>(
              stream: Provider.of<StorageService>(context).watchCards(),
              builder: (context, snapshot) {
                // Hide FAB if collection is empty
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(); // Return empty container instead of null
                }
                
                // Otherwise show the FAB
                return AnimatedBuilder(
                  animation: _fadeInController,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.6,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _fadeInController,
                        curve: Curves.easeOutBack,
                      )),
                      child: FloatingActionButton(
                        onPressed: () {
                          if (_showCustomCollections) {
                            _showCreateBinderDialog(context);
                          } else {
                            // Update this navigation logic to ensure it goes to the search screen
                            final homeState = context.findAncestorStateOfType<HomeScreenState>();
                            if (homeState != null) {
                              homeState.setSelectedIndex(2); // Index 2 is the Search tab
                            } else {
                              // Alternative navigation if not inside HomeScreen
                              Navigator.of(context).pushNamed('/search');
                            }
                          }
                        },
                        backgroundColor: colorScheme.primary,
                        elevation: 4,
                        child: Icon(
                          _showCustomCollections ? Icons.create_new_folder : Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : null,
    );
  }

  // Add the set distribution method inside the class
  Widget _buildSetDistribution(List<TcgCard> cards) {
    final purchaseService = Provider.of<PurchaseService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Get sorted sets
    final sortedSets = _getSetDistribution(cards);
    final totalCards = cards.length;
    final displaySets = sortedSets.take(6).toList(); // Show top 6 sets

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Fix the syntax error by using proper conditional rendering
          if (purchaseService.isPremium)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Content for premium users would go here
                  Text('Set Distribution Analysis'),
                  SizedBox(height: 12),
                  // Other widgets for premium users
                ],
              ),
            )
          else
            _buildPremiumOverlay(purchaseService),
        ],
      ),
    );
  }
  
  // Add premium overlay method inside the class
  Widget _buildPremiumOverlay(PurchaseService purchaseService) {
    return Container(
      color: Colors.black45,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Premium Feature',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock detailed set analytics',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => purchaseService.purchasePremium(),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}

// Helper class for background animation
class _CollectionParticle {
  Offset position;
  final double size;
  final double speed;
  final double angle;
  Color color;

  _CollectionParticle({
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
    required this.color,
  });
}

// Background painter for animated particles
class _CollectionBackgroundPainter extends CustomPainter {
  final List<_CollectionParticle> particles;
  final bool isDark;
  final Color primaryColor;
  final bool animate;

  _CollectionBackgroundPainter({
    required this.particles,
    required this.isDark,
    required this.primaryColor,
    this.animate = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Only update positions when animate is true
    if (animate) {
      for (final particle in particles) {
        // Calculate new position
        double newX = (particle.position.dx + cos(particle.angle) * particle.speed);
        double newY = (particle.position.dy + sin(particle.angle) * particle.speed);
        
        // Guard against NaN values
        if (newX.isNaN) newX = 0;
        if (newY.isNaN) newY = 0;
        
        // Ensure position is within bounds
        newX = newX.isFinite ? newX % size.width : 0;
        newY = newY.isFinite ? newY % size.height : 0;
        
        particle.position = Offset(newX, newY);
      }
    }
    
    // Draw particles with simplified rendering
    final paint = Paint();
    
    for (final particle in particles) {
      // Skip invalid positions
      if (particle.position.dx.isNaN || particle.position.dy.isNaN) continue;
      
      // Draw particles with less glow
      paint.color = particle.color;
      canvas.drawCircle(particle.position, particle.size, paint);
      
      // Only add glow to visible particles for better performance
      if (particle.position.dx > 0 && 
          particle.position.dx < size.width &&
          particle.position.dy > 0 && 
          particle.position.dy < size.height) {
        final glowPaint = Paint()
          ..color = particle.color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawCircle(particle.position, particle.size * 1.2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_CollectionBackgroundPainter oldDelegate) {
    return animate && oldDelegate.animate;
  }
}

// Custom tween for string animation
class FixedTween extends Tween<String> {
  final String end;
  
  FixedTween({required this.end}) : super(begin: '0', end: end);
  
  @override
  String lerp(double t) {
    // For numeric values, smoothly animate from 0 to final value
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(end)) {
      try {
        final endValue = double.parse(end.replaceAll(RegExp(r'[^\d.]'), ''));
        final currentValue = endValue * t;
        
        // For integers
        if (end.indexOf('.') == -1) {
          return currentValue.toInt().toString();
        }
        
        // For currency
        // Fix the syntax error here - was using 'contains' as an operator
        if (end.contains('\$') || end.contains('€') || end.contains('£')) {
          final symbol = RegExp(r'[\$€£]').firstMatch(end)?.group(0) ?? '';
          return '$symbol${currentValue.toStringAsFixed(2)}';
        }
        
        // Default decimal formatting
        return currentValue.toStringAsFixed(2);
      } catch (_) {
        return end;
      }
    }
    
    // For non-numeric values, just use the end value
    return end;
  }
}

void _showSortMenu(BuildContext context) {
  final sortProvider = Provider.of<SortProvider>(context, listen: false);
  
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                const Icon(Icons.sort),
                const SizedBox(width: 12),
                Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var option in CollectionSortOption.values)
                    RadioListTile<CollectionSortOption>(
                      value: option,
                      groupValue: sortProvider.currentSort,
                      onChanged: (value) {
                        sortProvider.setSort(value!);
                        Navigator.pop(context);
                      },
                      title: Text(_getSortOptionLabel(option)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _getSortOptionLabel(CollectionSortOption option) {
  switch (option) {
    case CollectionSortOption.nameAZ:
      return 'Name (A-Z)';
    case CollectionSortOption.nameZA:
      return 'Name (Z-A)';
    case CollectionSortOption.valueHighLow:
      return 'Value (High to Low)';
    case CollectionSortOption.valueLowHigh:
      return 'Value (Low to High)';
    case CollectionSortOption.newest:
      return 'Date Added (Newest First)';
    case CollectionSortOption.oldest:
      return 'Date Added (Oldest First)';
    case CollectionSortOption.countHighLow:
      return 'Card Count (High to Low)';
    case CollectionSortOption.countLowHigh:
      return 'Card Count (Low to High)';
  }
}

Future<void> _showCreateBinderDialog(BuildContext context) async {
  final collectionId = await showDialog<String>(
    context: context,
    builder: (context) => const CreateBinderDialog(),
    useSafeArea: true,
  );

  if (collectionId != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Binder Created',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Add cards to get started',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fix currency display issues in collections screen

// Find where collection values are displayed and update to use currencyProvider.formatValue consistently
Widget _buildCollectionValueSummary(BuildContext context, List<TcgCard> cards) {
  final currencyProvider = Provider.of<CurrencyProvider>(context);
  final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
  
  return Container(
    // ...existing code...
    child: Column(
      // ...existing code...
      children: [
        Text(
          currencyProvider.formatValue(totalValue),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        // ...existing code...
      ],
    ),
  );
}

// Also check collection list items to ensure they use the same currency format
Widget _buildCollectionListItem(BuildContext context, String name, int cardCount, double value) {
  final currencyProvider = Provider.of<CurrencyProvider>(context);
  return ListTile(
    // ...existing code...
    trailing: Text(
      currencyProvider.formatValue(value),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.green.shade700,
      ),
    ),
    // ...existing code...
  );
}