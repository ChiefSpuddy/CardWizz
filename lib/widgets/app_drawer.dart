import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Drawer(
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return Column(
            children: [
              // Gradient header
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,  // Center vertically
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: appState.currentUser?.avatarPath != null
                              ? ClipOval(
                                  child: Image.asset(
                                    appState.currentUser!.avatarPath!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 32,
                                  color: colorScheme.primary,
                                ),
                        ),
                        if (appState.isAuthenticated)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              width: 14,
                              height: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,  // Keep column tight
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.currentUser?.username != null
                                ? 'Hey, ${appState.currentUser?.username}!'
                                : appState.currentUser?.name ?? 'Welcome!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,  // Increased from 20
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (appState.currentUser?.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              appState.currentUser!.email!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,  // Increased from 12
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Menu items in scrollable list
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 8),
                    // Primary Navigation Group
                    _buildNavigationGroup(
                      context: context,
                      items: [
                        DrawerItem(
                          icon: Icons.home_outlined,
                          title: localizations.translate('home'),
                          fontSize: 15,  // Add fontSize parameter
                          onTap: () => _navigateAndClose(context, '/'),
                        ),
                        DrawerItem(
                          icon: Icons.style_outlined,
                          title: localizations.translate('collection'),
                          fontSize: 15,  // Add fontSize parameter
                          onTap: () => _navigateAndClose(context, AppRoutes.collection),
                        ),
                        DrawerItem(
                          icon: Icons.collections_bookmark_outlined,
                          title: localizations.translate('binders'),
                          onTap: () => _navigateAndClose(context, AppRoutes.collection),
                        ),
                        DrawerItem(
                          icon: Icons.analytics_outlined,
                          title: localizations.translate('analytics'),
                          onTap: () => _navigateAndClose(context, AppRoutes.analytics),
                        ),
                        DrawerItem(
                          icon: Icons.search_outlined,
                          title: 'Search',
                          onTap: () => _navigateAndClose(context, '/search'),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    // Settings Group
                    _buildNavigationGroup(
                      context: context,
                      title: 'Settings',
                      items: [
                        DrawerItem(
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
                        DrawerItem(
                          icon: isDark ? Icons.light_mode : Icons.dark_mode,
                          title: isDark ? 'Light Mode' : 'Dark Mode',
                          onTap: () {
                            appState.toggleTheme();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    if (appState.isAuthenticated) ...[
                      const Divider(height: 1),
                      _buildNavigationGroup(
                        context: context,
                        items: [
                          DrawerItem(
                            icon: Icons.logout,
                            title: 'Sign Out',
                            textColor: Colors.red,
                            onTap: () {
                              Navigator.pop(context);
                              appState.signOut();
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationGroup({
    required BuildContext context,
    String? title,
    required List<DrawerItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ...items.map((item) => _buildDrawerItem(context, item)),
      ],
    );
  }

  Widget _buildDrawerItem(BuildContext context, DrawerItem item) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        item.icon,
        color: item.textColor ?? Theme.of(context).colorScheme.onSurface,
        size: 22,  // Increased from 20
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: item.textColor,
          fontSize: item.fontSize,  // Use fontSize parameter
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: const TextStyle(fontSize: 13),  // Increased from 12
            )
          : null,
      onTap: item.onTap,
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
