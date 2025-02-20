import 'dart:ui';  // Add this import
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';
import '../services/tcg_api_service.dart';  // Add this import
import '../screens/card_details_screen.dart';  // Add this import
import '../models/tcg_card.dart';  // Add this import

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn(BuildContext context) async {
    if (_isSigningIn) return;

    setState(() => _isSigningIn = true);
    try {
      final user = await Provider.of<AppState>(context, listen: false)
          .signInWithApple();
      if (user == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // Background animation
        Positioned.fill(
          child: Opacity(
            opacity: 0.15,
            child: Lottie.asset(
              'assets/animations/background.json',
              fit: BoxFit.cover,
              controller: _animationController,
            ),
          ),
        ),
        
        // Main content
        CustomScrollView(
          slivers: [
            // Welcome Header
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    children: [
                      // App Logo
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary.withOpacity(0.9),
                                colorScheme.secondary.withOpacity(0.9),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.style_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Welcome Text with staggered animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              'Welcome to CardWizz',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your Personal Card Collection Assistant',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Features List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Choose CardWizz?',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildFeatureList(context),
                  ],
                ),
              ),
            ),

            // New Sign In Section
            _buildSignInSection(context),

            // Latest Set Preview
            if (!_isSigningIn) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Set Preview',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to start tracking your collection',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildLatestSetPreview(context),
            ],

            // New Stats Section
            _buildStatsSection(context),

            // Add Privacy Info
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your privacy is protected',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => _showPrivacyInfo(context),
                      child: const Text('Learn More'),
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

  Widget _buildSignInSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get Started',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _isSigningIn ? null : () => _handleSignIn(context),
              icon: _isSigningIn 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.apple, color: Colors.white, size: 24),
              label: Text(
                _isSigningIn ? 'Signing in...' : 'Continue with Apple',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Removed "Coming Soon" section and disabled buttons
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join Our Community',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  '5.0★',
                  'App Rating',
                  Icons.star_rounded,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  '5K+',
                  'Collectors',
                  Icons.group_rounded,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  '100K+',
                  'Cards Added',
                  Icons.style_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestSetPreview(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: FutureBuilder(
          future: Provider.of<TcgApiService>(context, listen: false)
              .searchCards(
                query: 'set.id:sv8pt5 (rarity:"Special Illustration Rare" OR rarity:"Illustration Rare" OR rarity:"Illustration Rare Secret")',
                orderBy: 'number',
                orderByDesc: true,
                pageSize: 200,
              ),
          builder: (context, snapshot) {
            final cards = (snapshot.data?['data'] as List?)?.toList() ?? [];
            
            // Take first 25 cards immediately instead of filtering again
            final displayCards = cards.take(25).toList();
            
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: displayCards.isEmpty ? 5 : displayCards.length,
              itemBuilder: (context, index) {
                if (displayCards.isEmpty) {
                  return _buildLoadingCard(context);
                }

                final card = displayCards[index];
                final imageUrl = card['images']['small'] as String?;
                if (imageUrl == null) {
                  return _buildLoadingCard(context);
                }
                    
                return GestureDetector(
                  onTap: () {
                    // Convert API response to TcgCard model
                    final tcgCard = TcgCard(
                      id: card['id'],
                      name: card['name'],
                      number: card['number'],
                      imageUrl: card['images']['small'],
                      largeImageUrl: card['images']['large'],
                      rarity: card['rarity'],
                      set: card['set'] != null ? TcgSet(
                        id: card['set']['id'],
                        name: card['set']['name'],
                        series: card['set']['series'],
                        total: card['set']['total'],
                      ) : null,
                      price: card['cardmarket']?['prices']?['averageSellPrice'],
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailsScreen(
                          card: tcgCard,
                          heroContext: 'preview_${tcgCard.id}',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 4, bottom: 8), // Changed from 8 to 4
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Column(  // Wrapped in Column for padding
                        children: [
                          Expanded(  // Make image take remaining space
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              cacheWidth: 200,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildLoadingCard(context);
                              },
                              errorBuilder: (context, error, stackTrace) => 
                                _buildLoadingCard(context),
                            ),
                          ),
                          const SizedBox(height: 8),  // Added padding at bottom
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 2), // Changed from 8 to 4
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showSignInPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Sign In Required',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to view and track cards in your collection',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleSignIn(context);
                  },
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeatureList(BuildContext context) {
    final features = [
      (Icons.inventory_2_rounded, 'Track Your Collection', 'Keep track of all your cards in one place'),
      (Icons.price_change_rounded, 'Live Prices', 'Stay updated with current market values'),
      (Icons.folder_copy_rounded, 'Custom Binders', 'Organize your cards your way'),
      // Removed Trade Tools
    ];

    return [
      ...features.map((feature) => Container(
        margin: const EdgeInsets.only(bottom: 12), // Reduced from 20
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Changed from start
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduced from 12
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                feature.$1,
                size: 24, // Reduced from 28
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12), // Reduced from 16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.$2,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith( // Reduced from titleMedium
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced from 4
                  Text(
                    feature.$3,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith( // Reduced from bodyMedium
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.2, // Reduced from 1.3
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    ];
  }

  void _showPrivacyInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy & Security',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Sign in with Apple for enhanced privacy',
                'Your data is stored securely',
                'No tracking or third-party analytics',
                'Export or delete your data anytime']
            .map((text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: 12),
                  Text(text),
                ],
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
