import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Add this import
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
import 'dart:math';

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
      print('Setting multiselect active: $active'); // Debug print
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = context.watch<CurrencyProvider>();
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Debug print to verify state is correct during build
    print('Building CollectionsScreen, multiselect active: $_isMultiselectActive');

    return Scaffold(
      key: _scaffoldKey,
      
      // Clean design with minimal AppBar
      appBar: isSignedIn 
        ? PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: AppBar(
              toolbarHeight: 44, 
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: false, 
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    Icons.menu, 
                    color: colorScheme.onBackground,
                  ),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              title: Text(
                'Collection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.sort,
                    color: colorScheme.onBackground,
                  ),
                  onPressed: () => _showSortMenu(context),
                ),
              ],
            ),
          )
        : null,
      
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      extendBody: true,
      
      // Body with stack for beautiful backgrounds and animations
      body: NotificationListener<ScrollNotification>(
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
        child: AnimatedBuilder(
          animation: _fadeInController,
          builder: (context, child) {
            return Stack(
              children: [
                // FIX: Correctly nest the particles background
                // The issue is here - Positioned must be direct child of Stack
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
                
                // Background gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Main content
                if (!isSignedIn)
                  const SignInView()
                else
                  SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        
                        // Collection stats and value tracker
                        StreamBuilder<List<TcgCard>>(
                          stream: Provider.of<StorageService>(context).watchCards(),
                          builder: (context, snapshot) {
                            final cards = snapshot.data ?? [];
                            if (cards.isEmpty) return const SizedBox.shrink();
                            
                            return _buildValueTrackerCard(cards, currencyProvider);
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // New animated toggle
                        _buildAnimatedToggle(),
                        
                        const SizedBox(height: 16),
                        
                        // Collection content
                        Expanded(
                          child: FutureBuilder<List<TcgCard>>(
                            future: Provider.of<StorageService>(context).getCards(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              final cards = snapshot.data ?? [];
                              
                              if (_pageViewReady) {
                                if (cards.isEmpty) {
                                  return const EmptyCollectionView(
                                    title: 'Start Your Collection',
                                    message: 'Add cards to build your collection',
                                    buttonText: 'Browse Cards',
                                    icon: Icons.add_circle_outline,
                                  );
                                }
                                
                                return AnimatedOpacity(
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
                                );
                              } else {
                                return const Center(child: CircularProgressIndicator());
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      
      // Only show FAB when not in multiselect mode
      floatingActionButton: isSignedIn && !_isMultiselectActive
          ? AnimatedBuilder(
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
            )
          : null,
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