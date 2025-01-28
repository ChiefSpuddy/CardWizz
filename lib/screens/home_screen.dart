import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this import
import '../providers/app_state.dart';
import 'home_overview.dart';
import 'collections_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_drawer.dart';
import 'analytics_screen.dart';  // Add this import

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
    NavItem(icon: Icons.home_outlined, label: 'Home'),
    NavItem(icon: Icons.style_outlined, label: 'Collection'),
    NavItem(icon: Icons.search_outlined, label: 'Search'),
    NavItem(icon: Icons.analytics_outlined, label: 'Analytics'),
    NavItem(icon: Icons.person_outline, label: 'Profile'),
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

  void setSelectedIndex(int index) async {
    setState(() => _selectedIndex = index);
    // Save selected index
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_tab_index', index);
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
    return WillPopScope(  // Add this wrapper
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        return true;
      },
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
              Positioned(  // Add custom menu button
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
              labelSmall: const TextStyle(fontSize: 11), // This will affect the nav bar labels
            ),
          ),
          child: NavigationBar(
            height: 60,  // Keep nav bar compact
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setSelectedIndex(index),
            destinations: List.generate(
              _navItems.length,
              (index) => NavigationDestination(
                icon: _buildBottomNavItem(context, index),
                label: _navItems[index].label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
