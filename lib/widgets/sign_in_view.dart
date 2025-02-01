import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';

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
    final bottomPadding = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;

    return Stack(
      children: [
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
        SafeArea(
          bottom: false, // Don't apply SafeArea to bottom
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo - made more compact
                Container(
                  padding: const EdgeInsets.all(16),
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
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.style_rounded,
                    size: 40, // Reduced from 56
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20), // Reduced from 32

                // Welcome Text - more compact
                Text(
                  'Welcome to CardWizz',
                  style: textTheme.headlineSmall?.copyWith( // Reduced from headlineMedium
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4), // Reduced from 8
                Text(
                  'Your Personal Card Collection Assistant',
                  style: textTheme.bodyMedium?.copyWith( // Reduced from titleMedium
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24), // Reduced from 40

                // Features list
                ..._buildFeatureList(context),
                const SizedBox(height: 24), // Reduced from 40

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  height: 48, // Reduced from 56
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
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
                      : const Icon(Icons.apple),
                    label: Text(
                      _isSigningIn ? 'Signing in...' : 'Continue with Apple',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                if (kDebugMode) ...[
                  const SizedBox(height: 8), // Reduced from 16
                  TextButton(
                    onPressed: _isSigningIn ? null : () {
                      // Debug sign in code...
                    },
                    child: const Text('Debug: Skip Sign In'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureList(BuildContext context) {
    final features = [
      (Icons.inventory_2_rounded, 'Track Collection', 'Keep track of all your cards in one place'),
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
}
