import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';  // Add this import
import '../providers/app_state.dart';
import '../l10n/app_localizations.dart';  // Add this import
import 'home_overview.dart';
import 'collections_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_drawer.dart';
import 'analytics_screen.dart';  // Add this import
import '../services/purchase_service.dart';  // Add this import
import '../providers/sort_provider.dart';  // Add this import

// Add NavItem class at the top level
class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home_outlined, label: 'home'),
    NavItem(icon: Icons.style_outlined, label: 'collections'),
    NavItem(icon: Icons.search_outlined, label: 'search'),  // This will now use the 'search' translation key
    NavItem(icon: Icons.analytics_outlined, label: 'analytics'),
    NavItem(icon: Icons.person_outline, label: 'profile'), // This will use the 'profile' translation
  ];

  final List<Widget> _pages = const [
    HomeOverview(),
    CollectionsScreen(),
    SearchScreen(),
    AnalyticsScreen(),  // Add Analytics page
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Restore selected index from storage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSelectedIndex();
    });
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('selected_tab_index') ?? 0;
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
  }

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();  // Add haptic feedback
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildBottomNavItem(BuildContext context, int index) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    
    // Custom profile icon/avatar for the profile tab
    if (index == 4) { // Assuming 4 is the index for the profile tab
      if (user != null && user.avatarPath != null) {
        return CircleAvatar(
          radius: 14,
          backgroundColor: _selectedIndex == index 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          child: CircleAvatar(
            radius: 12,
            backgroundImage: AssetImage(user.avatarPath!),
          ),
        );
      }
      return Icon(
        Icons.person_outline,
        color: _selectedIndex == index
            ? Theme.of(context).colorScheme.primary
            : null,
      );
    }

    // Return regular icons for other tabs
    final iconData = _navItems[index].icon;
    return Icon(
      iconData,
      color: _selectedIndex == index
          ? Theme.of(context).colorScheme.primary
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SortProvider(),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: Builder(
          builder: (context) => Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.copyWith(
              labelSmall: const TextStyle(fontSize: 11),
            ),
          ),
          child: NavigationBar(
            height: 60,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();  // Add haptic feedback
              setSelectedIndex(index);
            },
            destinations: List.generate(
              _navItems.length,
              (index) => NavigationDestination(
                icon: _buildBottomNavItem(context, index),
                label: AppLocalizations.of(context).translate(_navItems[index].label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
