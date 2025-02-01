import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/app_state.dart';
import '../providers/currency_provider.dart';  // Add this import
import '../routes.dart';
import '../screens/collections_screen.dart';  // Add this import
import '../screens/analytics_screen.dart';  // Add this import
import '../l10n/app_localizations.dart';  // Add this import

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigateAndClose(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Drawer(
          width: MediaQuery.of(context).size.width * 0.6, // Changed from 0.75 to 0.6
          backgroundColor: isDark 
              ? Colors.black.withOpacity(0.7) 
              : Colors.white.withOpacity(0.9),
          child: Consumer<AppState>(
            builder: (context, appState, _) {
              return Column(
                children: [
                  // Slimmer header with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16, // Reduced padding
                      bottom: 16, // Reduced padding
                      left: 16, // Reduced padding
                      right: 16, // Reduced padding
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withOpacity(0.8),
                          colorScheme.secondary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        // Smaller avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 15, // Reduced blur
                                spreadRadius: 1, // Reduced spread
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'avatar',
                            child: CircleAvatar(
                              radius: 24, // Reduced radius
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: appState.currentUser?.avatarPath != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        appState.currentUser!.avatarPath!,
                                        width: 44, // Reduced size
                                        height: 44, // Reduced size
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 28, color: Colors.white), // Reduced icon size
                            ),
                          ),
                        ),
                        const SizedBox(width: 12), // Reduced spacing
                        // User info with adjusted text sizes
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.currentUser?.name ?? 'Welcome!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18, // Reduced font size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (appState.currentUser?.email != null)
                                Text(
                                  appState.currentUser!.email!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13, // Reduced font size
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu items with new styling
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.home_rounded,
                          title: 'Home',
                          onTap: () => _navigateAndClose(context, '/'),
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.style_outlined,
                          title: 'Collection', // Fixed capitalization
                          onTap: () => _navigateAndClose(context, AppRoutes.collection),
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.collections_bookmark_outlined,
                          title: localizations.translate('binders'),
                          onTap: () => _navigateAndClose(context, AppRoutes.collection),
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.analytics_outlined,
                          title: localizations.translate('analytics'),
                          onTap: () => _navigateAndClose(context, AppRoutes.analytics),
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.search_outlined,
                          title: 'Search',
                          onTap: () => _navigateAndClose(context, '/search'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            height: 32,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        // Settings Group
                        _buildMenuItem(
                          context,
                          icon: Icons.currency_exchange,
                          title: 'Currency',
                          subtitle: currencyProvider.currentCurrency,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => _buildCurrencyPicker(
                                context,
                                currencyProvider,
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: isDark ? Icons.light_mode : Icons.dark_mode,
                          title: isDark ? 'Light Mode' : 'Dark Mode',
                          onTap: () {
                            appState.toggleTheme();
                            Navigator.pop(context);
                          },
                        ),
                        if (appState.isAuthenticated) ...[
                          const Divider(height: 1),
                          _buildMenuItem(
                            context,
                            icon: Icons.logout,
                            title: 'Sign Out',
                            onTap: () {
                              Navigator.pop(context);
                              appState.signOut();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = ModalRoute.of(context)?.settings.name == title.toLowerCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? (isDark ? colorScheme.primary.withOpacity(0.15) : colorScheme.primary.withOpacity(0.1))
                : Colors.transparent,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? colorScheme.primary : (isDark ? Colors.white : Colors.black87),
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyPicker(
    BuildContext context,
    CurrencyProvider currencyProvider,
  ) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text(
              'Select Currency',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: TextButton(
              child: const Text('Done'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Divider(height: 1),
          ...currencyProvider.currencies.entries.map(
            (entry) => ListTile(
              title: Text('${entry.key} (${entry.value.$1})'),
              trailing: currencyProvider.currentCurrency == entry.key
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                currencyProvider.setCurrency(entry.key);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final double fontSize;  // Add fontSize parameter
  final VoidCallback onTap;

  DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.textColor,
    this.fontSize = 15,  // Default fontSize
    required this.onTap,
  });
}
