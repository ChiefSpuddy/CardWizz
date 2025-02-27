import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './home_screen.dart';
import './collections_screen.dart';
import './search_screen.dart';
import './analytics_screen.dart';
import './collection_index_screen.dart';
import './profile_screen.dart';
import '../constants/app_colors.dart';

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CollectionsScreen(),
    SearchScreen(),
    AnalyticsScreen(),
    CollectionIndexScreen(),
    ProfileScreen(),
  ];

  void _onNavigationItemTapped(int index) {
    if (_selectedIndex == index) {
      // Handle same tab tap (e.g., scroll to top)
      if (index == 2) { // Search tab
        SearchScreen.clearSearchState(context);
      }
    } else {
      HapticFeedback.lightImpact();
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _onNavigationItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.style_outlined),
            activeIcon: Icon(Icons.style),
            label: 'Collection',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Tracker',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
