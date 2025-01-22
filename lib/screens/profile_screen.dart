import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';  // Add this import
import '../models/tcg_card.dart';  // Add this import
import '../widgets/avatar_picker_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectAvatar(BuildContext context) async {
    final avatarPath = await showDialog<String>(
      context: context,
      builder: (context) => const AvatarPickerDialog(),
    );

    if (avatarPath != null && context.mounted) {
      try {
        await context.read<AppState>().updateAvatar(avatarPath);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update avatar')),
          );
        }
      }
    }
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '€${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '€${(value / 1000).toStringAsFixed(1)}K';
    }
    return '€${value.toStringAsFixed(2)}';
  }

  Widget _buildStatsCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FittedBox(  // Add this wrapper
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,  // Reduced from 24
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,  // Add this
                overflow: TextOverflow.ellipsis,  // Add this
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, AuthUser user) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = user.name ?? '';
    final initial = user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : '';
    
    return StreamBuilder<List<TcgCard>>(
      stream: Provider.of<StorageService>(context).watchCards(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];
        final totalValue = cards.fold<double>(
          0,
          (sum, card) => sum + (card.price ?? 0),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              child: Column(
                children: [
                  Container(
                    height: 60, // Even smaller header
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -30), // Adjusted for smaller header
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _selectAvatar(context),
                          child: CircleAvatar(
                            radius: 35, // Smaller avatar
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 33,
                              backgroundColor: colorScheme.primary,
                              child: user.avatarPath != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        user.avatarPath!,
                                        width: 66,
                                        height: 66,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : initial.isNotEmpty
                                      ? Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 30,
                                          color: Colors.white,
                                        ),
                            ),
                          ),
                        ),
                        if (displayName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (user.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.email!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12), // Reduced padding
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    'Total Cards',
                    cards.length.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatsCard(
                    'Collections',
                    (cards.isEmpty ? '0' : '1'),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatsCard(
                    'Value',
                    _formatValue(totalValue),  // Use new format method
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Settings Section
            Card(
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement notifications toggle
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    trailing: const Text('English'),
                    onTap: () {
                      // TODO: Implement language selection
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text('Backup Collection'),
                    onTap: () {
                      // TODO: Implement backup
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      context.watch<AppState>().isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.grey,
                    ),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: context.watch<AppState>().isDarkMode,
                      onChanged: (bool value) => context.read<AppState>().toggleTheme(),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account Section
            Card(
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit Profile'),
                    onTap: () {
                      // TODO: Implement profile editing
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Privacy Settings'),
                    onTap: () {
                      // TODO: Implement privacy settings
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      context.read<AppState>().signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildSignInView(BuildContext context) {
    return Center(  // Add this wrapper
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,  // Add this
          children: [
            Icon(
              Icons.account_circle,
              size: 80, // Reduced from 100
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to view your profile',
              style: TextStyle(
                fontSize: 18, // Reduced from 20
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 250, // Fixed width for the button
              height: 44, // Fixed height for the button
              child: SignInWithAppleButton(
                onPressed: () => _handleSignIn(context),
                style: SignInWithAppleButtonStyle.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      final user = await Provider.of<AppState>(context, listen: false)
          .signInWithApple();
      if (user == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final isSignedIn = appState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Lottie.asset(
                'assets/animations/background.json',
                fit: BoxFit.cover,
                repeat: true,
                frameRate: FrameRate(30),
                controller: _animationController,
              ),
            ),
          ),
          SafeArea(
            child: isSignedIn && user != null
                ? _buildProfileContent(context, user)
                : _buildSignInView(context),
          ),
        ],
      ),
    );
  }
}