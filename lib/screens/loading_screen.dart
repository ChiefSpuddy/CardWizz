import 'package:flutter/material.dart';
import 'dart:math' as math;  // Add this import for math operations
import '../constants/app_colors.dart';  // Add this import for AppColors

class LoadingScreen extends StatefulWidget {
  final double progress;
  final String message;
  
  const LoadingScreen({
    Key? key,
    this.progress = 0.0,
    this.message = 'Loading...',
  }) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  // Use multiple animation controllers for complex animations
  late AnimationController _mainController;
  late AnimationController _cardsController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<double> _fadeInOut;

  // Preconfigured card positions for the fan animation
  final List<CardPosition> _cardPositions = [
    CardPosition(angle: -0.35, scale: 0.8, offsetX: -20, offsetY: 5),
    CardPosition(angle: -0.15, scale: 0.85, offsetX: -10, offsetY: 0),
    CardPosition(angle: 0.0, scale: 0.9, offsetX: 0, offsetY: -5),
    CardPosition(angle: 0.15, scale: 0.85, offsetX: 10, offsetY: 0),
    CardPosition(angle: 0.35, scale: 0.8, offsetX: 20, offsetY: 5),
  ];

  @override
  void initState() {
    super.initState();
    
    // Main animation controller for overall effects
    _mainController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Secondary controller specifically for card animations
    _cardsController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    // Create smooth animations
    _logoScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut)
    );
    
    _logoRotate = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut)
    );
    
    _fadeInOut = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use app colors for consistent theming
    final primaryColor = isDark ? AppColors.darkAccentPrimary : AppColors.primary;
    final secondaryColor = isDark ? AppColors.darkAccentSecondary : AppColors.secondary;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final subtextColor = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    
    // Create a beautiful gradient background
    final gradientColors = isDark 
      ? [
          AppColors.darkBackground,
          Color.lerp(AppColors.darkBackground, primaryColor, 0.12) ?? AppColors.darkBackground,
        ]
      : [
          AppColors.background,
          Color.lerp(AppColors.background, primaryColor.withOpacity(0.05), 0.15) ?? AppColors.background,
        ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Subtle particle effect
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GentleParticlesPainter(
                      animation: _mainController,
                      color: primaryColor,
                      density: isDark ? 12 : 10,
                    ),
                  );
                },
              ),
            ),
            
            // Main centered content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  
                  // Animated fan of trading cards - the core visual
                  SizedBox(
                    height: size.height * 0.32,
                    width: size.width * 0.9,
                    child: _buildAnimatedCardFan(primaryColor, secondaryColor, isDark),
                  ),

                  const SizedBox(height: 40),
                  
                  // App title with gradient shader
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'CardWizz',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        height: 0.9,
                        fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tagline
                  Text(
                    'Your Ultimate Card Collection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: subtextColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Custom progress bar
                  _buildProgressBar(context, primaryColor, secondaryColor),
                  
                  // Loading message - nicely animated
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInOut.value,
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // App version at bottom
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v1.0.5',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtextColor.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The animated fan of trading cards
  Widget _buildAnimatedCardFan(Color primaryColor, Color secondaryColor, bool isDark) {
    return AnimatedBuilder(
      animation: _cardsController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Create each card in the fan
            for (int i = 0; i < _cardPositions.length; i++) 
              _buildAnimatedCard(
                i, 
                primaryColor, 
                secondaryColor, 
                _cardsController.value, 
                isDark
              ),
              
            // Glow effect in the center
            Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withOpacity(0.1 * _fadeInOut.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Individual animated card in the fan
  Widget _buildAnimatedCard(int index, Color primaryColor, Color secondaryColor, 
                          double animationValue, bool isDark) {
    // Calculate animation phase for this card
    final cardPosition = _cardPositions[index];
    final phaseOffset = index * 0.2; // Each card is slightly out of phase
    final cardAnimation = (animationValue + phaseOffset) % 1.0;
    
    // Calculate dynamic position and rotation
    final angle = cardPosition.angle + 
                 math.sin(cardAnimation * math.pi * 2) * 0.05;
    final scale = cardPosition.scale * 
                 (0.98 + math.sin(cardAnimation * math.pi * 2) * 0.02);
    final offsetX = cardPosition.offsetX + 
                  math.cos(cardAnimation * math.pi * 2) * 3;
    final offsetY = cardPosition.offsetY + 
                  math.sin(cardAnimation * math.pi * 2) * 2;
                  
    // Create card gradient based on position
    final cardColor = Color.lerp(
      primaryColor, 
      secondaryColor, 
      (index / (_cardPositions.length - 1))
    )!;
    
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: AspectRatio(
                // FIXED: Change aspect ratio to be vertical (2:3) like real trading cards
                aspectRatio: 0.7, // Vertical card ratio (width:height)
                child: _buildTradingCard(cardColor, isDark, index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A trading card visual with realistic design - completely revamped
  Widget _buildTradingCard(Color cardColor, bool isDark, int index) {
    // Card type selection based on index
    final cardType = index % 3; // 0: Pokémon, 1: MTG, 2: Standard
    
    // Card gradients that change based on the index and card type
    final gradientIntensity = 0.05 + (index * 0.02);
    
    // Different card colors based on type
    final Color baseColor;
    final Color accentColor;
    
    // Assign color schemes based on card type
    switch (cardType) {
      case 0: // Pokémon
        baseColor = Color.lerp(cardColor, Colors.yellow, 0.3)!;
        accentColor = Color.lerp(cardColor, Colors.red, 0.2)!;
        break;
      case 1: // MTG
        baseColor = Color.lerp(cardColor, Colors.brown, 0.2)!;
        accentColor = Color.lerp(cardColor, Colors.orange, 0.2)!;
        break;
      case 2: // Standard/Modern style
      default:
        baseColor = cardColor;
        accentColor = Color.lerp(cardColor, Colors.blue, 0.2)!;
        break;
    }
    
    final topColor = Color.lerp(
      baseColor, 
      Colors.white, 
      isDark ? gradientIntensity * 0.4 : gradientIntensity * 0.8
    )!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4), // Reduced horizontal margin
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [topColor, baseColor],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(2, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.2) : Colors.white,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildCardTypeContent(cardType, baseColor, accentColor, isDark, index),
      ),
    );
  }

  // NEW: Different card content based on card type
  Widget _buildCardTypeContent(int cardType, Color baseColor, Color accentColor, bool isDark, int index) {
    switch (cardType) {
      case 0:
        return _buildPokemonCardContent(baseColor, accentColor, isDark, index);
      case 1:
        return _buildMagicCardContent(baseColor, accentColor, isDark, index);
      case 2:
      default:
        return _buildModernCardContent(baseColor, accentColor, isDark, index);
    }
  }

  // NEW: Pokémon-style card content
  Widget _buildPokemonCardContent(Color baseColor, Color accentColor, bool isDark, int index) {
    // Add specific pokémon card styling
    return Stack(
      children: [
        // Card background with texture
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  baseColor.withOpacity(0.8),
                  baseColor.withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),
        
        // Pokemon name area - moved to top for vertical orientation
        Positioned(
          top: 8,
          left: 12,
          height: 20,
          right: 65, // Make room for HP on right
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black38 : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        
        // HP indicator
        Positioned(
          top: 8,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${70 + index * 10} HP', // Random HP value based on index
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10, // Smaller text for vertical
              ),
            ),
          ),
        ),
        
        // Card artwork area - positioned for vertical orientation
        Positioned(
          top: 30, // Moved down to make room for name
          left: 12,
          right: 12,
          height: 100, // Taller artwork area for vertical card
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.7 : 0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            // Placeholder for character image
            child: Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withOpacity(0.7),
                      baseColor.withOpacity(0.3),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        
        // Type indicator
        Positioned(
          top: 134, // Below artwork
          left: 15,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
          ),
        ),
        
        // First attack
        Positioned(
          top: 170,
          left: 12,
          right: 12,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            // Energy symbols
            child: Row(
              children: [
                const SizedBox(width: 6),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                // Attack name placeholder
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Spacer(),
                // Damage counter
                Container(
                  width: 30,
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    '${10 * (index + 1)}',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Second attack
        Positioned(
          top: 205,
          left: 12,
          right: 12,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            // Energy symbols
            child: Row(
              children: [
                const SizedBox(width: 6),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 30,
                  height: 20,
                  alignment: Alignment.center,
                  child: Text(
                    '${20 * (index + 1)}',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Pokemon info at bottom
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Set icon
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Rarity symbol
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Shiny foil effect overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.3, 0.6, 1.0],
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // NEW: Magic: The Gathering style card content
  Widget _buildMagicCardContent(Color baseColor, Color accentColor, bool isDark, int index) {
    // Add specific MTG card styling
    return Stack(
      children: [
        // Card background with texture
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withOpacity(0.8),
                  baseColor,
                ],
              ),
            ),
          ),
        ),
        
        // Title bar
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(3),
            ),
            // Card name placeholder
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 6,
                  color: Colors.white.withOpacity(0.7),
                ),
                const Spacer(),
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${1 + (index % 3)}', // Mana cost
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Card artwork area - larger for MTG
        Positioned(
          top: 30,
          left: 8,
          right: 8,
          height: 120, // Increased height for vertical card
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            // Art frame
            child: Center(
              child: Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withOpacity(0.8),
                      baseColor.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Card type line
        Positioned(
          top: 155, // Adjusted for vertical orientation
          left: 8,
          right: 8,
          height: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(3),
            ),
            // Type line placeholder
            child: Center(
              child: Container(
                width: 80,
                height: 6,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
        
        // Text box - larger for vertical card
        Positioned(
          top: 175, // Positioned below type line
          left: 8,
          right: 8,
          bottom: 28, // Leave room for P/T box
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.7),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.black.withOpacity(0.3),
                width: 1,
              ),
            ),
            // Text lines
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 5,
                  color: Colors.black.withOpacity(0.2),
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: 80,
                  height: 5,
                  color: Colors.black.withOpacity(0.2),
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: 100,
                  height: 5,
                  color: Colors.black.withOpacity(0.2),
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: 70,
                  height: 5,
                  color: Colors.black.withOpacity(0.2),
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: 90,
                  height: 5,
                  color: Colors.black.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ),
        
        // Power/Toughness box
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.black.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Text(
              '${1 + index % 3}/${1 + index % 2}', // Power/Toughness
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        
        // Set symbol
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // NEW: Modern/Standard trading card content
  Widget _buildModernCardContent(Color baseColor, Color accentColor, bool isDark, int index) {
    // Standard trading card style
    return Stack(
      children: [
        // Holographic background effect
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, // Changed to top-to-bottom
                end: Alignment.bottomCenter,
                colors: [
                  baseColor.withOpacity(0.9),
                  accentColor.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        
        // Card border
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.7),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        
        // Card title at top
        Positioned(
          top: 8,
          left: 10,
          right: 10,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  baseColor,
                ],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 1,
                  spreadRadius: 0,
                ),
              ],
            ),
            // Title placeholder
            child: Center(
              child: Container(
                width: 80,
                height: 8,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
        
        // Main image area - enlarged for vertical card
        Positioned(
          top: 32,
          left: 10,
          right: 10,
          height: 160, // Much taller for vertical card
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.2 : 0.8),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            // Image placeholder
            child: Center(
              child: Container(
                width: 90, // Wider
                height: 120, // Much taller
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withOpacity(0.9),
                      baseColor.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                // Add some inner design
                child: Center(
                  child: Icon(
                    Icons.star,
                    size: 40,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Card stats and info
        Positioned(
          top: 196,
          left: 10,
          right: 10,
          height: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark 
                ? Colors.black.withOpacity(0.4) 
                : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                // Attack
                Container(
                  width: 30,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      '${10 * (index + 1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Defense
                Container(
                  width: 30,
                  height: 20,
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Center(
                    child: Text(
                      '${5 * (index + 1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Card description
        Positioned(
          bottom: 30,
          left: 10,
          right: 10,
          height: 50, // Taller for vertical card
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.2 : 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            // Text placeholder lines
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: double.infinity,
                  height: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
                Container(
                  width: 70,
                  height: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
                Container(
                  width: 90,
                  height: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
        
        // Card number and set symbol at bottom
        Positioned(
          bottom: 8,
          left: 10,
          right: 10,
          height: 16,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}', // Card number
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.star,
                    color: accentColor,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Foil overlay effect
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, // Changed to vertical
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.2, 0.8, 1.0],
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Animated progress bar
  Widget _buildProgressBar(BuildContext context, Color primaryColor, Color secondaryColor) {
    final hasProgress = widget.progress > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Progress track
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark 
                ? AppColors.darkDivider.withOpacity(0.4)
                : primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasProgress 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Progress fill
                      FractionallySizedBox(
                        widthFactor: widget.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, secondaryColor],
                            ),
                          ),
                        ),
                      ),
                      
                      // Animated shine effect - FIXED: Use Matrix4 instead of Transform.skew
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Positioned(
                            left: -100 + (300 * _mainController.value),
                            top: 0,
                            bottom: 0,
                            width: 60,
                            child: Transform(
                              // Use Matrix4 to create a skew transformation
                              transform: Matrix4.skewX(-0.4),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0),
                                      Colors.white.withOpacity(0.4),
                                      Colors.white.withOpacity(0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              : Center(
                  child: AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Container(
                        height: 6,
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.3),
                              primaryColor,
                              primaryColor.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Positioned(
                                left: -100 + (300 * _mainController.value),
                                top: 0,
                                bottom: 0,
                                width: 40,
                                child: Transform(
                                  // FIXED: Use Matrix4 here too
                                  transform: Matrix4.skewX(-0.4),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0),
                                          Colors.white.withOpacity(0.4),
                                          Colors.white.withOpacity(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ),
          
          // Percentage text
          if (hasProgress)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${(widget.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Position data for cards in the fan
class CardPosition {
  final double angle;
  final double scale;
  final double offsetX;
  final double offsetY;
  
  CardPosition({
    required this.angle,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

// Gentle particle effect
class GentleParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final List<ParticleData> particles = [];
  final int density;
  
  GentleParticlesPainter({
    required this.animation,
    required this.color,
    this.density = 10,
  }) {
    if (particles.isEmpty) {
      for (int i = 0; i < density; i++) {
        particles.add(ParticleData.random(color));
      }
    }
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate position based on animation
      final progress = (animation.value + particle.offset) % 1.0;
      final x = particle.x * size.width;
      final y = size.height - (progress * size.height * 1.2);
      
      if (y > 0 && y < size.height) {
        final paint = Paint()
          ..color = particle.color.withOpacity(particle.opacity * (1 - progress * 0.7))
          ..style = PaintingStyle.fill;
          
        // Draw particle
        canvas.drawCircle(
          Offset(x, y),
          particle.size,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Particle data class
class ParticleData {
  final double x;
  final double size;
  final Color color;
  final double offset;
  final double opacity;
  
  ParticleData({
    required this.x,
    required this.size,
    required this.color,
    required this.offset,
    required this.opacity,
  });
  
  factory ParticleData.random(Color baseColor) {
    return ParticleData(
      x: math.Random().nextDouble(),
      size: 0.3 + math.Random().nextDouble() * 1.8,
      color: baseColor,
      offset: math.Random().nextDouble(),
      opacity: 0.05 + math.Random().nextDouble() * 0.08,
    );
  }
}
