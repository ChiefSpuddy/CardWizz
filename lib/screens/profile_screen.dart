import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../providers/currency_provider.dart';
import '../widgets/avatar_picker_dialog.dart';
import '../l10n/app_localizations.dart';  // Fix this import path
import '../screens/privacy_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  String _deleteConfirmation = '';

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
        // Prevent auto-pop by using mounted check
        if (!context.mounted) return;
        
        await context.read<AppState>().updateAvatar(avatarPath);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update avatar')),
          );
        }
      }
    }
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final appState = context.read<AppState>();
    final currentLocale = appState.locale.languageCode;

    final Map<String, String> languages = {
      'en': 'English',
      'es': 'Español',
      'ja': '日本語',
    };

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              trailing: currentLocale == entry.key
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                appState.setLocale(entry.key);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _editUsername(BuildContext context, AuthUser user) async {
    final controller = TextEditingController(text: user.username);
    final formKey = GlobalKey<FormState>();

    final newUsername = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Enter your username',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username cannot be empty';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, controller.text);
              }
            },
          ),
        ],
      ),
    );

    if (newUsername != null && context.mounted) {
      try {
        // Prevent auto-pop by using mounted check
        if (!context.mounted) return;
        
        await context.read<AppState>().updateUsername(newUsername);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username updated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update username')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action cannot be undone. Please type "DELETE" to confirm.'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _deleteConfirmation = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(
              'Delete Account',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: _deleteConfirmation == 'DELETE'
                ? () => Navigator.pop(context, true)
                : null,
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AppState>().deleteAccount();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Widget _buildStatsCard(String title, String value, Color color) {
    final localizations = AppLocalizations.of(context);
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
              localizations.translate(title),  // Use translation here
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

  Widget _buildProfileHeader(BuildContext context, AuthUser user) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = user.name ?? '';
    final initial = user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : '';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(  // Add this wrapper
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,  // Make sure both columns stretch
              children: [
                // Avatar column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _selectAvatar(context),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: colorScheme.primary.withOpacity(0.2),
                              child: user.avatarPath != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        user.avatarPath!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : initial.isNotEmpty
                                      ? Text(initial,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                          ))
                                      : const Icon(Icons.person,
                                          size: 30, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avatar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (displayName.isNotEmpty)
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Username section with its own edit button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _editUsername(context, user),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.alternate_email,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user.username ?? 'Set username',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (user.email != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          user.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, AuthUser user) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final currencyProvider = context.watch<CurrencyProvider>();
    
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
            _buildProfileHeader(context, user),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatsCard(
                    'totalCards',  // Use translation key instead of direct string
                    cards.length.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatsCard(
                    'collections',
                    (cards.isEmpty ? '0' : '1'),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatsCard(
                    'value',
                    currencyProvider.formatValue(totalValue),
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
                      localizations.translate('settings'),  // Translate settings title
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
                    title: Text(localizations.translate('notifications')),  // Add new translation
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
                    title: Text(localizations.translate('language')),
                    trailing: Text(
                      context.select((AppState state) => 
                        state.locale.languageCode == 'es' ? 'Español' :
                        state.locale.languageCode == 'ja' ? '日本語' :
                        'English'
                      ),
                    ),
                    onTap: () => _showLanguageDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: Text(localizations.translate('backupCollection')),  // Add new translation
                    onTap: () {
                      // TODO: Implement backup
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: Text(localizations.translate('currency')),  // Add new translation
                    trailing: DropdownButton<String>(
                      value: currencyProvider.currentCurrency,
                      onChanged: (String? value) {
                        if (value != null) {
                          currencyProvider.setCurrency(value);
                        }
                      },
                      items: currencyProvider.currencies.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text('${entry.key} (${entry.value.$1})'),
                              ))
                          .toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      context.watch<AppState>().isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.grey,
                    ),
                    title: Text(localizations.translate('darkMode')),  // Add new translation
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
                      localizations.translate('account'),  // Add new translation
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
                    title: Text(localizations.translate('editProfile')),  // Add new translation
                    onTap: () {
                      // TODO: Implement profile editing
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: Text(localizations.translate('privacySettings')),  // Add new translation
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      localizations.translate('signOut'),  // Add new translation
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      context.read<AppState>().signOut();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildDangerZone(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildDangerZone() {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildSection(
      context: context,
      title: 'Danger Zone',
      titleColor: colorScheme.error,
      backgroundColor: colorScheme.errorContainer.withOpacity(0.1),
      children: [
        ListTile(
          leading: Icon(
            Icons.delete_forever,
            color: colorScheme.error,
          ),
          title: Text(
            'Delete Account',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'This will permanently delete your account and all data',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    Color? titleColor,
    Color? backgroundColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: titleColor ?? Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
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