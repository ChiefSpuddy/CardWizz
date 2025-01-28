import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/currency_provider.dart';  // Add this import
import '../routes.dart';

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
    final appState = context.watch<AppState>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: ListView(
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
            title: const Text('Home'),
            onTap: () {
              _navigateAndClose(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.collections),
            title: const Text('Collection'),
            onTap: () {
              _navigateAndClose(context, '/collection');
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            onTap: () {
              _navigateAndClose(context, '/search');
            },
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
      ),
    );
  }
}
