import 'dart:async';  // Add this import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';  // Add this import
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
import '../services/collection_service.dart';
import '../widgets/styled_toast.dart';  // Add this import
import '../providers/theme_provider.dart'; // Add this import
import '../widgets/app_drawer.dart'; // Add this import
import '../widgets/standard_app_bar.dart'; // Add this import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _animationController;
  String _deleteConfirmation = '';
  late final ScrollController _scrollController;
  double? _scrollPosition;
  bool _showSensitiveInfo = false;
  bool _notificationsEnabled = false;
  bool _showPremiumInfo = false;
  Timer? _syncCheckTimer;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAppStoreReview() async {
    const appStoreId = '6740775089';  // Updated with your actual App Store ID
    final url = Uri.parse('https://apps.apple.com/app/id$appStoreId?action=write-review');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

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

    // Add periodic sync check
    _syncCheckTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted) {
        final storage = context.read<StorageService>();
        if (storage.isSyncEnabled) {
          storage.syncNow();
        }
      }
    });
  }

  @override
  void dispose() {
    _syncCheckTimer?.cancel();
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
            SnackBar(
              content: StyledToast(
                title: 'Avatar Updated',
                subtitle: 'Your profile picture has been changed successfully',
                icon: Icons.check_circle_outline,
                backgroundColor: Colors.green,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: StyledToast(
                title: 'Update Failed',
                subtitle: 'Could not update avatar',
                icon: Icons.error_outline,
                backgroundColor: Colors.red,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
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
            SnackBar(
              content: StyledToast(
                title: 'Username Updated',
                subtitle: 'Your username has been changed successfully',
                icon: Icons.check_circle_outline,
                backgroundColor: Colors.green,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: StyledToast(
                title: 'Update Failed',
                subtitle: 'Could not update username',
                icon: Icons.error_outline,
                backgroundColor: Colors.red,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
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

  Widget _buildProfileHeader(BuildContext context, AuthUser user) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = user.name ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _selectAvatar(context),
                  child: Hero(
                    tag: 'profileAvatar',
                    child: Container(
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
                        radius: 40,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: user.avatarPath != null
                            ? ClipOval(
                                child: Image.asset(
                                  user.avatarPath!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.username ?? 'Set username',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: colorScheme.onSecondaryContainer,
                            ),
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
                                color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                              ),
                        ),
                    ],
                  ),
                ),
              ],
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
    final purchaseService = context.watch<PurchaseService>();
    final storageService = Provider.of<StorageService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context); // Add this
    final isDark = themeProvider.isDarkMode; // Use this instead
    
    return StreamBuilder<List<TcgCard>>(
      stream: storageService.watchCards(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];
        
        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 1), // Reduced from 8

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
                  // 1. Core App Settings
                  ListTile(
                    leading: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
                    subtitle: Text(isDark ? 'Switch to light theme' : 'Switch to dark theme'),
                    onTap: () => themeProvider.toggleTheme(), // Use themeProvider
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.language, color: colorScheme.primary),
                    title: Text(localizations.translate('language')),
                    trailing: Container(
                      height: 48, // Match the height of the DropdownButton
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showLanguageDialog(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  context.select((AppState state) => 
                                    state.locale.languageCode == 'es' ? 'Español' :
                                    state.locale.languageCode == 'ja' ? '日本語' :
                                    'English'
                                  ),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.currency_exchange, color: colorScheme.primary),
                    title: Text(localizations.translate('currency')),
                    trailing: Container(
                      height: 48, // Match the height
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: const InputDecorationTheme(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        child: Center(
                          child: DropdownButton<String>(
                            value: currencyProvider.currentCurrency,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            isDense: true,
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
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // 2. Sync & Data
                  ListTile(
                    leading: const Icon(Icons.cloud_sync),
                    title: const Text('Cloud Sync'),
                    subtitle: Text(storageService.isSyncEnabled ? 'Auto-sync every 30 minutes' : 'Off'),
                    trailing: Switch(
                      value: storageService.isSyncEnabled,
                      onChanged: (enabled) {
                        final storage = context.read<StorageService>();
                        if (enabled) {
                          storage.startSync();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: StyledToast(
                                title: 'Cloud Sync Enabled',
                                subtitle: 'Your collection will sync every 30 minutes',
                                icon: Icons.cloud_done,
                                backgroundColor: Colors.green,
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              duration: const Duration(seconds: 2), // Reduced from default 4 seconds
                            ),
                          );
                        } else {
                          storage.stopSync();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: StyledToast(
                                title: 'Cloud Sync Disabled',
                                subtitle: 'Auto-sync turned off',
                                icon: Icons.cloud_off,
                                backgroundColor: Colors.orange,
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              duration: const Duration(seconds: 2), // Reduced from default 4 seconds
                            ),
                          );
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  if (storageService.isSyncEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.sync_rounded),
                      title: const Text('Sync Now'),
                      onTap: () async {
                        final storage = context.read<StorageService>();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: StyledToast(
                              title: 'Syncing...',
                              subtitle: 'Updating your collection',
                              icon: Icons.sync,
                              backgroundColor: Colors.blue,
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            duration: const Duration(milliseconds: 1500),
                          ),
                        );
                        
                        final wasSuccessful = await storage.syncNow();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: StyledToast(
                                title: wasSuccessful ? 'Sync Complete' : 'Sync Failed',
                                subtitle: wasSuccessful ? 'Your collection is up to date' : 'Please try again later',
                                icon: wasSuccessful ? Icons.check_circle_outline : Icons.error_outline,
                                backgroundColor: wasSuccessful ? Colors.green : Colors.red,
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  const Divider(height: 1),
                  // 3. Notifications (disabled for now)
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(localizations.translate('notifications')),
                    subtitle: const Text('Price alerts and updates'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: null,  // Coming soon
                    ),
                  ),
                  // 4. Information
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Data Sources'),
                    subtitle: const Text('Card data and market prices'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDataAttributionDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade600,
                          ],
                        ).createShader(bounds);
                      },
                      child: const Icon(
                        Icons.star_rounded, // Using rounded star for better appearance
                        size: 28, // Slightly larger icon
                      ),
                    ),
                    title: const Text(
                      'Rate CardWizz',  // Updated text to be more specific
                      style: TextStyle(
                        fontWeight: FontWeight.w500,  // Semi-bold text
                      ),
                    ),
                    subtitle: const Text(
                      'Love the app? Let us know!',  // Added encouraging subtitle
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: _openAppStoreReview,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),  // Reduced from 16

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
                      Uri.parse('https://cardwizz.com/privacy.html'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  const Divider(height: 1),
                  Container( // Add container for consistent padding
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildPremiumTile(context),
                  ),
                  if (_showPremiumInfo) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildPremiumInfoSection(context, purchaseService.isPremium),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton(
                        onPressed: () => setState(() => _showPremiumInfo = true),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Subscription Details',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.expand_more, 
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      localizations.translate('signOut'),
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () => context.read<AppState>().signOut(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),  // Reduced from 32
            _buildDangerZone(),
            const SizedBox(height: 16),  // Reduced from 32
          ],
        );
      },
    );
  }

  Widget _buildPremiumTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final purchaseService = context.watch<PurchaseService>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: purchaseService.isPremium
                  ? [
                      colorScheme.primaryContainer,
                      colorScheme.primary.withOpacity(0.2),
                    ]
                  : [
                      Colors.amber.shade200,
                      Colors.amber.shade100,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (purchaseService.isPremium
                        ? colorScheme.primary
                        : Colors.amber.shade300)
                    .withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: purchaseService.isPremium 
                ? () => _showPremiumInfoDialog(context) 
                : () => _initiatePremiumPurchase(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: purchaseService.isPremium
                          ? colorScheme.primary
                          : Colors.amber.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchaseService.isPremium ? 'Premium Active' : 'Upgrade to Premium',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          purchaseService.isPremium
                              ? 'All features unlocked'
                              : 'Unlock unlimited collections & more',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumInfoSection(BuildContext context, bool isPremium) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),  // Reduced horizontal margin
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: _showPremiumInfo ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: TextButton(
          onPressed: () => setState(() => _showPremiumInfo = true),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Show subscription details',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Icon(Icons.expand_more, size: 20),
            ],
          ),
        ),
        secondChild: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,  // Add this
            children: [
              ListTile(
                title: const Text('Subscription Details'),
                trailing: IconButton(
                  icon: const Icon(Icons.expand_less),
                  onPressed: () => setState(() => _showPremiumInfo = false),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CardWizz Premium',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Auto-Renewable Subscription',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('\$2.99 USD per month'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureComparison(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscription Information:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Subscription length: 1 month\n'
                            '• Payment charged to Apple ID account\n'
                            '• Subscription renews automatically\n'
                            '• Cancel anytime in App Store Settings\n'
                            '• Cancel at least 24h before renewal',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _launchUrl('https://chiefspuddy.github.io/CardWizz/#terms-of-service'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Center(  // Wrap with Center
                              child: Text(
                                'Terms of Use',
                                maxLines: 1,  // Add this to prevent text wrapping
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _launchUrl('https://cardwizz.com/privacy.html'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Center(  // Wrap with Center
                              child: Text(
                                'Privacy Policy',
                                maxLines: 1,  // Add this to prevent text wrapping
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),    // Feature description
        1: FlexColumnWidth(2.5),  // Free column - increased for better text fit
        2: FlexColumnWidth(2.5),  // Premium column - increased for better text fit
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Free', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Premium', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        _buildFeatureRow('Collection Size', '200', 'Unlimited'),
        _buildFeatureRow('Card Scanning', '50/mo', 'Unlimited'),
        _buildFeatureRow('Collections', '4 max', 'Unlimited'),  // Changed from Collections/Binders
        _buildFeatureRow('Analytics', 'Basic', 'Advanced'),
        _buildFeatureRow('Market Data', 'Basic', 'Enhanced'),
        // Removed custom themes and background refresh as they're not implemented
      ],
    );
  }

  TableRow _buildFeatureRow(String feature, String free, String premium) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            feature,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Center(  // Add Center wrapper
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              free,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        Center(  // Add Center wrapper
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                premium,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPremiumInfoDialog(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final isPremium = purchaseService.isPremium;
    
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
        content: SingleChildScrollView(  // Add scroll support for smaller screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subscription Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Monthly subscription\n'
                      '• \$2.99 USD per month\n'
                      '• Auto-renews unless cancelled\n'
                      '• Cancel anytime in App Store',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Premium Features Include:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...['✨ Unlimited card collection (Free: 200)',
                  '🔍 Unlimited card scanning (Free: 50/mo)',
                  '📊 Advanced analytics and tracking',
                  '📈 Enhanced market data',
                  '📱 Multiple collections (Free: 4)']
                  .map((feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, 
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (!isPremium)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _initiatePremiumPurchase(context);
                  },
                  icon: const Text('💎'),
                  label: const Text('Subscribe Now'),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _initiatePremiumPurchase(BuildContext context) async {
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to App Store...'),
          ],
        ),
      ),
    );
    
    try {
      // Store initial premium state
      final wasPremiumBefore = purchaseService.isPremium;
      
      // Attempt to make the purchase
      await purchaseService.purchasePremium();
      
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Check if premium state changed to determine success
      final isPremiumNow = purchaseService.isPremium;
      final purchaseSucceeded = !wasPremiumBefore && isPremiumNow;
      
      if (context.mounted) {
        if (purchaseSucceeded || isPremiumNow) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: StyledToast(
                title: 'Premium Activated!',
                subtitle: 'Thank you for your support. Enjoy all premium features!',
                icon: Icons.check_circle_outline,
                backgroundColor: Colors.green,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
          // Force UI refresh
          setState(() {});
        } else if (!isPremiumNow) {
          // Purchase was canceled or failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: StyledToast(
                title: 'Subscription Not Completed',
                subtitle: 'Premium subscription was not purchased',
                icon: Icons.info_outline,
                backgroundColor: Colors.orange,
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          );
        }
      }
    } catch (e) {
      // Handle errors
      if (context.mounted) Navigator.of(context).pop(); // Close loading dialog
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: StyledToast(
              title: 'Subscription Error',
              subtitle: 'Could not process subscription. Please try again later.',
              icon: Icons.error_outline,
              backgroundColor: Colors.red,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        );
      }
    }
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CardWizz uses the following data sources:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildAttributionItem(
                'Pokémon TCG API',
                'Card data and market prices for Pokémon cards',
                'https://pokemontcg.io/'
              ),
              const SizedBox(height: 8),
              _buildAttributionItem(
                'Scryfall API',
                'Card data and pricing information for Magic: The Gathering cards',
                'https://scryfall.com/docs/api'
              ),
              const SizedBox(height: 8),
              _buildAttributionItem(
                'TCGdex API',
                'Japanese Pokémon card data and translations',
                'https://www.tcgdex.net/'
              ),
              const SizedBox(height: 8),
              _buildAttributionItem(
                'PokéAPI',
                'Pokémon species data and information',
                'https://pokeapi.co/'
              ),
              const SizedBox(height: 8),
              _buildAttributionItem(
                'eBay API',
                'Market data and recent sales information',
                'https://developer.ebay.com/'
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'All card images, logos, symbols, and related information are copyright of their respective owners. CardWizz is not affiliated with, endorsed by, or sponsored by any of these services or companies.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
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

  Widget _buildAttributionItem(String title, String description, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        TextButton(
          onPressed: () => launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerLeft,
          ),
          child: Text('Visit $title'),
        ),
      ],
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
            Icons.cleaning_services,  // New icon for clear data
            color: colorScheme.error,
          ),
          title: Text(
            'Clear Collection Data',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Remove all cards and collection history. This cannot be undone.',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          onTap: _showClearDataDialog,
        ),
        const Divider(height: 1),
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

  Future<void> _showClearDataDialog() async {
    double sliderValue = 0.0;
    final colorScheme = Theme.of(context).colorScheme;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Clear Collection Data',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.error.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will permanently remove:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...['All cards in your collection',
                        'Price history data',
                        'Collection statistics',
                        'Custom binders and organization']
                        .map((text) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.remove_circle_outline,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                sliderValue > 0.9 ? 'Release to confirm' : 'Slide to confirm',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.error.withOpacity(0.1),
                      colorScheme.error.withOpacity(0.2),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background gradient for the active part
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: MediaQuery.of(context).size.width * sliderValue,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.error.withOpacity(0.5),
                              colorScheme.error,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Slider instruction text
                    if (sliderValue < 0.9)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              'Slide to clear data',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    // The actual slider
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 56,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: colorScheme.error,
                        overlayColor: colorScheme.error.withOpacity(0.12),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 14,
                          elevation: 4,
                          pressedElevation: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 24,
                        ),
                      ),
                      child: Slider(
                        value: sliderValue,
                        onChanged: (value) {
                          setState(() => sliderValue = value);
                          if (value >= 0.95) {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final storage = context.read<StorageService>();
        final collections = await CollectionService.getInstance();
        final appState = context.read<AppState>();
        
        // Use current user from AppState
        if (appState.currentUser != null) {
          await storage.permanentlyDeleteUserData();
          await collections.permanentlyDeleteUserData(appState.currentUser!.id);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Collection data cleared successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing data: $e')),
          );
        }
      }
    }
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final localizations = AppLocalizations.of(context);
    final currencyProvider = context.watch<CurrencyProvider>();
    final translationKey = title == 'Total Cards' ? 'totalCards' : 
                          title == 'Collection Value' ? 'portfolioValue' : 
                          title.toLowerCase().replaceAll(' ', '_');
    
    // Format the value if it's currency related
    final String formattedValue;
    if (title.toLowerCase().contains('value')) {
      final numericValue = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
      formattedValue = numericValue != null 
          ? currencyProvider.formatValue(numericValue)
          : value;
    } else {
      formattedValue = value;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              title.toLowerCase().contains('value') 
                  ? Icons.currency_exchange
                  : icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate(translationKey),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedValue,  // Use the formatted value
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: isSignedIn ? const StandardAppBar(
        transparent: true,
        elevation: 0,
      ) : null, // Hide app bar when not signed in
      drawer: const AppDrawer(),
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
            child: isSignedIn && context.watch<AppState>().currentUser != null
                ? _buildProfileContent(context, context.watch<AppState>().currentUser!)
                : const SignInView(
                    showAppBar: false, // Explicitly set to false
                    showNavigationBar: false,
                  ),
          ),
        ],
      ),
    );
  }
}