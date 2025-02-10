import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';  // Add this import
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../providers/currency_provider.dart';
import '../widgets/avatar_picker_dialog.dart';
import '../l10n/app_localizations.dart';  // Fix this import path
import '../screens/privacy_settings_screen.dart';
import '../services/purchase_service.dart';  // Make sure this is added
import 'package:flutter/foundation.dart';  // Add this import for kDebugMode
import '../widgets/sign_in_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  String _deleteConfirmation = '';
  late final ScrollController _scrollController;
  double? _scrollPosition;
  bool _showSensitiveInfo = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      _scrollPosition = _scrollController.position.pixels;
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();  // Add this
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
      elevation: 1, // Reduced elevation
      margin: EdgeInsets.zero, // Remove margin
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // Reduced padding
        child: Column(
          children: [
            FittedBox(  // Add this wrapper
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18, // Reduced from 20
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,  // Add this
                overflow: TextOverflow.ellipsis,  // Add this
              ),
            ),
            const SizedBox(height: 2), // Reduced from 4
            Text(
              localizations.translate(title),  // Use translation here
              style: TextStyle(
                fontSize: 11, // Reduced from 12
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

    return AnimatedContainer( // Add animation to header
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 4), // Reduced from 8
      child: Column(
        children: [
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 400),
            tween: Tween<double>(begin: 0.5, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => _selectAvatar(context),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40, // Slightly larger avatar
                      backgroundColor: colorScheme.primaryContainer,
                      child: user.avatarPath != null
                          ? ClipOval(
                              child: Image.asset(
                                user.avatarPath!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : initial.isNotEmpty
                              ? Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : const Icon(Icons.person, size: 40),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
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
            ),
          ),
          const SizedBox(height: 8), // Reduced from 12
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.username ?? 'Set username',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: () => _editUsername(context, user),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          if (user.email != null)
            Text(
              user.email!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, AuthUser user) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final currencyProvider = context.watch<CurrencyProvider>();
    final purchaseService = context.watch<PurchaseService>();  // Move this outside StreamBuilder
    
    return StreamBuilder<List<TcgCard>>(
      stream: Provider.of<StorageService>(context).watchCards(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];
        final totalValue = cards.fold<double>(
          0,
          (sum, card) => sum + (card.price ?? 0),
        );

        return ListView(
          controller: _scrollController,  // Add this
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16), // Remove top padding
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 4), // Reduced from 8

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
                const SizedBox(width: 2), // Reduced from 4
                Expanded(
                  child: _buildStatsCard(
                    'collections',
                    (cards.isEmpty ? '0' : '1'),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 2), // Reduced from 4
                Expanded(
                  child: _buildStatsCard(
                    'value',
                    currencyProvider.formatValue(totalValue),
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // Reduced from 16

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
                    title: Text(localizations.translate('notifications')),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: null,
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
                      Theme.of(context).brightness == Brightness.dark 
                          ? Icons.dark_mode 
                          : Icons.light_mode,
                    ),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: (_) => context.read<AppState>().toggleTheme(),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Background Refresh'),
                    trailing: Switch(
                      value: context.select((StorageService s) => 
                        s.backgroundService?.isEnabled ?? false),
                      onChanged: (value) {
                        final storage = context.read<StorageService>();
                        if (value) {
                          storage.backgroundService?.startPriceUpdates();
                        } else {
                          storage.backgroundService?.stopPriceUpdates();
                        }
                        setState(() {}); // Refresh UI
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Data Sources'),
                    subtitle: const Text('Card data and prices powered by third-party APIs'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDataAttributionDialog(context),
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
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(localizations.translate('privacyPolicy')),
                    onTap: () => launchUrl(
                      Uri.parse('https://chiefspuddy.github.io/CardWizz/#privacy-policy'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  const Divider(height: 1),
                  _buildPremiumTile(context),
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

  Widget _buildPremiumTile(BuildContext context) {
    final purchaseService = context.watch<PurchaseService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: purchaseService.isPremium 
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: purchaseService.isPremium 
              ? null  // Disable tap when premium
              : () async {
                  if (purchaseService.isLoading) return;
                  try {
                    await purchaseService.purchasePremium();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: purchaseService.isPremium ? colorScheme.primary : Colors.amber,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (purchaseService.error != null)
                        Text(
                          purchaseService.error!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (purchaseService.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (purchaseService.isPremium)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showPremiumInfoDialog(context),
                        tooltip: 'Premium Features',
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showPremiumInfoDialog(context),
                        tooltip: 'Premium Features',
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                if (kDebugMode && purchaseService.isPremium) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => purchaseService.clearPremiumStatus(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPremiumInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Premium Features'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your premium subscription includes:'),
            const SizedBox(height: 16),
            ...['✨ Unlimited card collection',
                '📊 Advanced analytics and tracking',
                '📱 Custom themes and card scanning',
                '💾 Cloud backup and restore',
                '📈 Real-time market data']
                .map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataAttributionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Data Attribution'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CardWizz uses the following data sources:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Card data and market prices are provided by the Pokémon TCG API\n'
              '• Images and card information are owned by their respective copyright holders\n'
              '• CardWizz is not affiliated with or endorsed by these services',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://docs.pokemontcg.io/'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('API Documentation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleThemeChange(bool value) {
    // Store current scroll position
    final scrollOffset = _scrollController.offset;
    
    // Toggle theme
    context.read<AppState>().toggleTheme();
    
    // Restore scroll position on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.positions.isNotEmpty) {
        _scrollController.jumpTo(scrollOffset);
      }
    });
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
            'Warning - This will permanently delete your account and all associated data.',
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final isSignedIn = appState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 40),
          onPressed: () => Scaffold.of(context).openDrawer(),
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
                : const SignInView(),
          ),
        ],
      ),
    );
  }
}