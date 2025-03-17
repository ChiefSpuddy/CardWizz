import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/app_state.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart'; 
import '../routes.dart';
import '../screens/collections_screen.dart';
import '../screens/analytics_screen.dart';
import '../l10n/app_localizations.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart'; 
import '../services/navigation_service.dart';
import '../services/logging_service.dart'; // Add this import

class AppDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const AppDrawer({
    super.key,
    this.scaffoldKey,
  });

  // Simplify the navigation method to handle search without mode parameter
  void _navigateAndClose(BuildContext context, String route, {Map<String, dynamic>? arguments}) {
    Navigator.pop(context); // Close drawer
    
    // Try to use bottom nav first
    final homeState = context.findRootAncestorStateOfType<HomeScreenState>();
    if (homeState != null) {
      switch (route) {
        case AppRoutes.home:
          homeState.setSelectedIndex(0);
          break;
        case AppRoutes.collection:
          homeState.setSelectedIndex(1);
          break;
        case AppRoutes.search:
          homeState.setSelectedIndex(2);
          break;
        case AppRoutes.analytics:
          homeState.setSelectedIndex(3);
          break;
        case AppRoutes.profile:
          homeState.setSelectedIndex(4);
          break;
        default:
          Navigator.pushNamed(context, route, arguments: arguments);
      }
    } else {
      // Fallback to direct navigation if not in HomeScreen
      Navigator.pushNamed(context, route, arguments: arguments);
    }
  }

  // Add the missing _buildMenuItem method
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

  // Add the missing _buildCurrencyPicker method
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
              title: Text('${entry.key} (${entry.value.symbol})'),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyProvider = context.watch<CurrencyProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final localizations = AppLocalizations.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Drawer(
          width: MediaQuery.of(context).size.width * 0.6,
          backgroundColor: isDark 
              ? Colors.black.withOpacity(0.7) 
              : Colors.white.withOpacity(0.9),
          child: Consumer<AppState>(
            builder: (context, appState, _) {
              final username = appState.currentUser?.username;
              return Column(
                children: [
                  // Slimmer header with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
                          colorScheme.primary.withOpacity(0.8),
                          colorScheme.secondary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'avatar',
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: appState.currentUser?.avatarPath != null
                                ? ClipOval(
                                    child: Image.asset(
                                      appState.currentUser!.avatarPath!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Log the error and show fallback icon
                                        LoggingService.debug('Error loading avatar image: $error');
                                        return const Icon(Icons.person, size: 28, color: Colors.white);
                                      },
                                    ),
                                  )
                                : const Icon(Icons.person, size: 28, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username ?? localizations.translate('welcome'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (appState.currentUser?.email != null)
                                Text(
                                  appState.currentUser!.email!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
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
                          onTap: () => _navigateAndClose(context, AppRoutes.home),
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.style_outlined,
                          title: 'Collection',
                          onTap: () => _navigateAndClose(context, AppRoutes.collection),
                        ),
                        // Simplified Search option - no mode specification
                        _buildMenuItem(
                          context,
                          icon: Icons.search,
                          title: 'Search',
                          onTap: () => _navigateAndClose(context, AppRoutes.search),
                        ),
                        // Analytics comes before Profile
                        _buildMenuItem(
                          context,
                          icon: Icons.analytics_outlined,
                          title: localizations.translate('analytics'),
                          onTap: () => _navigateAndClose(context, AppRoutes.analytics),
                        ),
                        // Profile comes after Analytics
                        _buildMenuItem(
                          context,
                          icon: Icons.account_circle,
                          title: 'Profile',
                          onTap: () => _navigateAndClose(context, AppRoutes.profile),
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
                            themeProvider.toggleTheme();
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
}

// DrawerItem class for any helpers
class DrawerItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final double fontSize;  
  final VoidCallback onTap;

  DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.textColor,
    this.fontSize = 15,  
    required this.onTap,
  });
}
