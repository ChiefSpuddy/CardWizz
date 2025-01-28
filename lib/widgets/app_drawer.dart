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
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return Drawer(
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: appState.currentUser?.avatarPath != null
                          ? ClipOval(
                              child: Image.asset(
                                appState.currentUser!.avatarPath!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.person, size: 35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      appState.currentUser?.name ?? 'Welcome!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    if (appState.currentUser?.email != null)
                      Text(
                        appState.currentUser!.email!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: Text(localizations.translate('home')),
                onTap: () => _navigateAndClose(context, '/'),
              ),
              ListTile(
                leading: const Icon(Icons.style),
                title: Text(localizations.translate('collection')),
                onTap: () => _navigateAndClose(context, AppRoutes.collection),
              ),
              ListTile(
                leading: const Icon(Icons.collections_bookmark),
                title: Text(localizations.translate('binders')),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  // Navigate to collections screen and set showCustomCollections to true
                  Navigator.pushNamed(context, AppRoutes.collection).then((_) {
                    if (context.mounted) {
                      final collectionsState = context
                          .findAncestorStateOfType<CollectionsScreenState>();
                      if (collectionsState != null) {
                        collectionsState.showCustomCollections = true;
                      }
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: Text(localizations.translate('analytics')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search'),
                onTap: () => _navigateAndClose(context, '/search'),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  _navigateAndClose(context, '/settings');
                },
              ),
              const Divider(),
              ExpansionTile(
                leading: const Icon(Icons.currency_exchange),
                title: const Text('Currency'),
                subtitle: Text(currencyProvider.currentCurrency),
                children: currencyProvider.currencies.entries.map((entry) {
                  return ListTile(
                    dense: true,
                    leading: const SizedBox(width: 16),
                    title: Text('${entry.key} (${entry.value.$1})'),
                    selected: currencyProvider.currentCurrency == entry.key,
                    onTap: () {
                      currencyProvider.setCurrency(entry.key);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              ListTile(
                leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                title: Text(isDark ? 'Light Mode' : 'Dark Mode'),
                onTap: () {
                  appState.toggleTheme();
                  Navigator.pop(context);
                },
              ),
              if (appState.isAuthenticated)
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () {
                    Navigator.pop(context);
                    appState.signOut();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
