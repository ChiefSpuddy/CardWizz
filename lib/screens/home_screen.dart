import 'package:flutter/material.dart';
import 'home_overview.dart';
import 'collections_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_drawer.dart';
import 'analytics_screen.dart';  // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();  // Add this

  final List<Widget> _pages = const [
    HomeOverview(),
    CollectionsScreen(),
    SearchScreen(),
    AnalyticsScreen(),  // Add Analytics page
    ProfileScreen(),
  ];

  void setSelectedIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,  // Use the key here
      drawer: const AppDrawer(),
      body: Builder(  // Add this wrapper
        builder: (context) => Stack(
          children: [
            _pages[_selectedIndex],
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
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22),
              selectedIcon: Icon(Icons.home, size: 22),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_outlined, size: 22),
              selectedIcon: Icon(Icons.collections, size: 22),
              label: 'Collection',
            ),
            NavigationDestination(
              icon: Icon(Icons.search, size: 22),
              selectedIcon: Icon(Icons.search, size: 22),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, size: 22),
              selectedIcon: Icon(Icons.analytics, size: 22),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 22),
              selectedIcon: Icon(Icons.person, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
