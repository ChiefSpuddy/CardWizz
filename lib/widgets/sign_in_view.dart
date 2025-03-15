import '../services/logging_service.dart';
import 'dart:ui';
import 'dart:math' as math;  // Add this import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/storage_service.dart';
import '../utils/hero_tags.dart';
import '../utils/error_handler.dart';
import '../widgets/animated_gradient_button.dart';
import '../widgets/styled_toast.dart';
import '../services/tcg_api_service.dart';  // Add this import

class SignInView extends StatefulWidget {
  final bool showNavigationBar;
  final bool showAppBar;

  const SignInView({
    super.key,
    this.showNavigationBar = false,
    this.showAppBar = false,
  });

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _logoController;
  late final AnimationController _headlineController;
  late final AnimationController _contentController;
  late final AnimationController _particleController;
  late final AnimationController _pulseController;
  
  bool _isSigningIn = false;
  bool _isLoading = false; // Add the missing _isLoading field
  
  final List<Map<String, dynamic>> _showcaseCards = [];
  bool _isLoadingCards = true;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _headlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    Future.delayed(const Duration(milliseconds: 100), () => _logoController.forward());
    Future.delayed(const Duration(milliseconds: 400), () => _headlineController.forward());
    Future.delayed(const Duration(milliseconds: 700), () => _contentController.forward());
    
    _loadShowcaseCards();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    _headlineController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadShowcaseCards() async {
    try {
      final apiService = Provider.of<TcgApiService>(context, listen: false);
      
      final response = await apiService.searchCards(
        query: 'rarity:"Secret Rare" OR rarity:"Alt Art"',
        pageSize: 8,
        orderBy: 'cardmarket.prices.averageSellPrice',
        orderByDesc: true,
      );

      if (mounted) {
        setState(() {
          _showcaseCards.clear();
          _showcaseCards.addAll((response['data'] as List? ?? []).cast<Map<String, dynamic>>());
          _isLoadingCards = false;
        });
      }
    } catch (e) {
      LoggingService.debug('Error loading showcase cards: $e');
      if (mounted) {
        setState(() => _isLoadingCards = false);
      }
    }
  }

  Future<void> _handleSignIn(BuildContext context) async {
    if (_isSigningIn) return;
    
    HapticFeedback.mediumImpact();

    setState(() => _isSigningIn = true);
    
    try {
      final user = await Provider.of<AppState>(context, listen: false)
          .signInWithApple();
          
      if (user == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in failed. Please try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  // Add method to handle Google sign-in
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await context.read<AppState>().signInWithGoogle();
      
      if (user != null && mounted) {
        // Sign-in successful
        // No need to navigate, AppState will handle this
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in with Google: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ) : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildAnimatedBackground(isDark, colorScheme),
          
          if (_showcaseCards.isNotEmpty)
            ..._buildFloatingCards(colorScheme),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAnimatedLogo(colorScheme, isDark),
                            
                            const SizedBox(height: 24), // Reduced from 32
                            
                            _buildAnimatedHeadline(colorScheme),
                            
                            const SizedBox(height: 20), // Reduced from 32
                            
                            _buildFeatureCards(context, colorScheme),
                            
                            const SizedBox(height: 24), // Reduced from 40
                            
                            _buildSignInButton(context, colorScheme),

                            const SizedBox(height: 12), // Reduced from 16
                            
                            _buildGoogleSignInButton(context, colorScheme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                _buildFooter(colorScheme),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showNavigationBar ? _buildBottomNavigationBar(context) : null,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (_) {
        showToast(
          context: context,
          title: 'Sign In Required',
          subtitle: 'Please sign in to continue',
          icon: Icons.login_rounded,
          isError: false,
          compact: true,
          duration: const Duration(seconds: 2),
        );
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.style_outlined),
          label: 'Collection',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_kabaddi_outlined),
          label: 'Arena',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground(bool isDark, ColorScheme colorScheme) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark 
                      ? colorScheme.surface.withAlpha((0.8 * 255).round())
                      : colorScheme.background.withAlpha((0.8 * 255).round()),
                    isDark
                      ? Color.lerp(colorScheme.surface, colorScheme.primary, 0.05) ?? colorScheme.surface
                      : Color.lerp(colorScheme.background, colorScheme.primary, 0.03) ?? colorScheme.background,
                    isDark
                      ? Color.lerp(colorScheme.surface, colorScheme.primary, 0.1) ?? colorScheme.surface
                      : Color.lerp(colorScheme.background, colorScheme.primary, 0.07) ?? colorScheme.background,
                    isDark
                      ? colorScheme.surface.withAlpha((0.8 * 255).round())
                      : colorScheme.background.withAlpha((0.8 * 255).round()),
                  ],
                  stops: [
                    0,
                    0.3 + (_backgroundController.value * 0.2),
                    0.6 + (_backgroundController.value * 0.2),
                    1,
                  ],
                ),
              ),
            );
          },
        ),
        
        Positioned.fill(
          child: Opacity(
            opacity: 0.05,
            child: CustomPaint(
              painter: CardPatternPainter(
                animation: _backgroundController.value,
                isDark: isDark,
                primaryColor: colorScheme.primary,
              ),
            ),
          ),
        ),
        
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                animation: _particleController.value,
                isDark: isDark,
                particleColor: colorScheme.primary.withAlpha((0.3 * 255).round()),
                particleCount: 60,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildAnimatedLogo(ColorScheme colorScheme, bool isDark) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final bounceValue = Curves.elasticOut.transform(
          _logoController.value
        );
        
        return Transform.scale(
          scale: bounceValue,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                      colorScheme.tertiary,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha((0.3 * 255).round() + (_pulseController.value * 0.2 * 255).round()),
                      blurRadius: 20 + (_pulseController.value * 8),
                      spreadRadius: 1 + (_pulseController.value * 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.style_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildAnimatedHeadline(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _headlineController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            30 * (1 - Curves.easeOutCubic.transform(_headlineController.value)),
          ),
          child: Opacity(
            opacity: _headlineController.value,
            child: Column(
              children: [
                Text(
                  'CardWizz',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Collect. Track. Value.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your complete card collection assistant',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onBackground.withAlpha((0.7 * 255).round()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFeatureCards(BuildContext context, ColorScheme colorScheme) {
    final features = [
      (
        'Collection Tracking',
        'Track every card with real-time values',
        Icons.style_rounded,
      ),
      (
        'Live Market Prices',
        'Stay updated with current market prices',
        Icons.trending_up_rounded,
      ),
      (
        'Custom Binders',
        'Organize your collection your way',
        Icons.folder_special_rounded,
      ),
    ];
    
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        return Column(
          children: List.generate(features.length, (index) {
            final delay = index * 0.2;
            final animationProgress = (_contentController.value - delay) / (1 - delay);
            final progress = animationProgress.clamp(0.0, 1.0);
            
            return Transform.translate(
              offset: Offset(
                30 * (1 - progress),
                0,
              ),
              child: Opacity(
                opacity: progress,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
                  padding: const EdgeInsets.all(10), // Reduced from 12
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surface.withAlpha((0.7 * 255).round()),
                    border: Border.all(
                      color: colorScheme.primary.withAlpha((0.1 * 255).round()),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha((0.05 * 255).round()),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // Reduced from 10
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          features[index].$3,
                          color: Colors.white,
                          size: 18, // Reduced from 20
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              features[index].$1,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            Text(
                              features[index].$2,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onBackground.withAlpha((0.7 * 255).round()),
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
          }),
        );
      },
    );
  }
  
  Widget _buildFooter(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        final delay = 0.5;
        final animationProgress = (_contentController.value - delay) / (1 - delay);
        final progress = animationProgress.clamp(0.0, 1.0);
        
        return Opacity(
          opacity: progress,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12), // Reduced from 16
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Privacy focused - your data stays on your device',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onBackground.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _showPrivacyInfo(context),
                  child: Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  List<Widget> _buildFloatingCards(ColorScheme colorScheme) {
    final random = math.Random(42);
    final screenSize = MediaQuery.of(context).size;
    
    return List.generate(
      math.min(6, _showcaseCards.length), 
      (index) {
        double top = random.nextDouble() * screenSize.height * 0.7;
        
        double left;
        if (index % 3 == 0) {
          left = -50 + random.nextDouble() * 40; 
        } else if (index % 3 == 1) {
          left = screenSize.width - 60 - random.nextDouble() * 40;
        } else {
          left = random.nextBool() 
              ? -50 + random.nextDouble() * 40
              : screenSize.width - 60 - random.nextDouble() * 40;
          top = random.nextDouble() * screenSize.height * 0.7;
        }
        
        final size = 80.0 + random.nextDouble() * 30;
        final rotation = (random.nextDouble() - 0.5) * 0.5;
        
        final card = _showcaseCards[index];
        final imageUrl = card['images']?['small'];
        
        if (imageUrl == null) return const SizedBox.shrink();
        
        return Positioned(
          top: top,
          left: left,
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              final wave = index % 2 == 0 ? math.sin : math.cos;
              final horizontalOffset = wave(_backgroundController.value * math.pi * 2 + index) * 5.0;
              final verticalOffset = wave(_backgroundController.value * math.pi * 2 + index * 0.7) * 5.0;
              final wobble = math.sin(_backgroundController.value * math.pi * 1.5 + index * 0.8) * 0.05;
              
              return Transform.translate(
                offset: Offset(horizontalOffset, verticalOffset),
                child: Transform.rotate(
                  angle: rotation + wobble,
                  child: child,
                ),
              );
            },
            child: Container(
              width: size,
              height: size * 1.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha((0.2 * 255).round()),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.15),
                  errorBuilder: (context, error, stackTrace) => 
                      Container(color: colorScheme.primary.withAlpha((0.05 * 255).round())),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build social sign-in buttons
  Widget _buildSocialSignInButton({
    required VoidCallback onPressed,
    required String icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed, // Add isLoading check
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 1,
        ),
        child: _isLoading ? // Show loading indicator if loading
          const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(),
          ) :
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use Icon widget as a temporary placeholder if the asset is missing
              icon == 'assets/icons/google_icon.png'
                  ? Container(
                      height: 24,
                      width: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Image.asset(icon, height: 24, width: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        final delay = 0.3;
        final animationProgress = (_contentController.value - delay) / (1 - delay);
        final progress = animationProgress.clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(
            0,
            30 * (1 - progress),
          ),
          child: Opacity(
            opacity: progress,
            child: AnimatedGradientButton(
              text: 'Sign in with Apple',
              icon: Icons.apple,
              isLoading: _isSigningIn,
              // Updated colors to match Apple's branding - black with slight gradient
              gradientColors: [
                Colors.black,
                Colors.black87,
              ],
              onPressed: () => _handleSignIn(context),
              height: 50, // Reduced from 55
              borderRadius: 16,
            ),
          ),
        );
      },
    );
  }

  // Add Google Sign-In button with matching style
  Widget _buildGoogleSignInButton(BuildContext context, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        final delay = 0.4; // Slightly delayed animation compared to Apple button
        final animationProgress = (_contentController.value - delay) / (1 - delay);
        final progress = animationProgress.clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(
            0,
            30 * (1 - progress),
          ),
          child: Opacity(
            opacity: progress,
            child: AnimatedGradientButton(
              text: 'Sign in with Google',
              // Custom content to include Google logo
              customContent: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 22, // Reduced from 24
                    width: 22, // Reduced from 24
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Reduced from 12
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 15, // Reduced from 16
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              isLoading: _isLoading,
              // Google brand color gradient
              gradientColors: [
                Colors.blue.shade700,
                Colors.lightBlue.shade500,
              ],
              onPressed: _handleGoogleSignIn,
              height: 50, // Reduced from 55
              borderRadius: 16,
            ),
          ),
        );
      },
    );
  }
}

class CardPatternPainter extends CustomPainter {
  final double animation;
  final bool isDark;
  final Color primaryColor;

  CardPatternPainter({
    required this.animation,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor.withAlpha(isDark ? (0.15 * 255).round() : (0.1 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
      
    const spacing = 100.0;
    const cardWidth = 50.0;
    const cardHeight = 70.0;
    const radius = 5.0;
    
    for (var x = -cardWidth; x < size.width + cardWidth; x += spacing) {
      for (var y = -cardHeight; y < size.height + cardHeight; y += spacing) {
        final offsetX = 8 * math.sin(animation * math.pi * 2 + (x + y) / 500);
        final offsetY = 8 * math.cos(animation * math.pi * 2 + (x - y) / 500);
        
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + offsetX, 
            y + offsetY, 
            cardWidth, 
            cardHeight
          ),
          const Radius.circular(radius),
        );
        
        canvas.drawRRect(rect, paint);
        
        final innerRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + offsetX + 3, 
            y + offsetY + 3, 
            cardWidth - 6, 
            cardHeight - 6
          ),
          const Radius.circular(3),
        );
        
        canvas.drawRRect(innerRect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CardPatternPainter oldDelegate) => true;
}

class ParticlePainter extends CustomPainter {
  final double animation;
  final bool isDark;
  final Color particleColor;
  final int particleCount;
  final List<_Particle> _particles = [];

  ParticlePainter({
    required this.animation,
    required this.isDark,
    required this.particleColor,
    this.particleCount = 60,
  }) {
    if (_particles.isEmpty) {
      final random = math.Random(42);
      for (int i = 0; i < particleCount; i++) {
        _particles.add(_Particle(
          position: Offset(
            random.nextDouble() * 2000,
            random.nextDouble() * 2000,
          ),
          size: 1.0 + random.nextDouble() * 2.5,
          opacity: 0.1 + random.nextDouble() * 0.3,
          speed: 0.2 + random.nextDouble() * 0.6,
        ));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final x = (particle.position.dx + animation * 100 * particle.speed) % size.width;
      final y = (particle.position.dy + animation * 80 * particle.speed) % size.height;
      
      final paint = Paint()
        ..color = particleColor.withAlpha((particle.opacity * 255).round());
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => animation != oldDelegate.animation;
}

class _Particle {
  final Offset position;
  final double size;
  final double opacity;
  final double speed;

  _Particle({
    required this.position,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}

void _showPrivacyInfo(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface.withAlpha((0.9 * 255).round()),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: colorScheme.primary.withAlpha((0.1 * 255).round()),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.privacy_tip_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Privacy & Security',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...['Your data is stored securely on your device',
                  'Sign in with Apple for enhanced privacy',
                  'No tracking or third-party analytics',
                  'Export or delete your data anytime']
                  .map((text) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withAlpha((0.1 * 255).round()),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: colorScheme.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(text)),
                      ],
                    ),
                  )).toList(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
