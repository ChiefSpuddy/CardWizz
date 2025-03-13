import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/collections_screen.dart'; // Change this from collection_screen.dart to collections_screen.dart
import '../screens/search_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/profile_screen.dart';
import '../constants/app_colors.dart';

class RootNavigator extends StatefulWidget {
  final int initialTab;
  
  // Add a static instance to track the current navigator state
  static _RootNavigatorState? _instance;
  
  const RootNavigator({Key? key, this.initialTab = 0}) : super(key: key);

  // Add a public static method to switch tabs
  static void switchToTab(BuildContext context, int index) {
    if (_instance != null) {
      _instance!.setCurrentIndex(index);
    } else {
      // Use Navigator to push a new RootNavigator with desired tab if no instance exists
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RootNavigator(initialTab: index),
        ),
        (route) => false,
      );
    }
  }

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  late int _currentIndex;
  final List<Widget> _screens = [
    const HomeScreen(),
    const CollectionsScreen(showEmptyState: true), // Update to use CollectionsScreen with the required parameter
    const SearchScreen(),
    const AnalyticsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    // Store instance for static access
    RootNavigator._instance = this;
  }
  
  @override
  void dispose() {
    // Remove instance reference when disposed
    if (RootNavigator._instance == this) {
      RootNavigator._instance = null;
    }
    super.dispose();
  }
  
  // Public method to change the current tab index
  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setCurrentIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDark 
            ? Colors.white.withOpacity(0.6) 
            : Colors.black54,
        backgroundColor: isDark 
            ? AppColors.darkCardBackground 
            : Colors.white,
        elevation: 8,
        // Make navigation bar more compact
        selectedFontSize: 11.0, // Reduced from default 14
        unselectedFontSize: 11.0, // Reduced from default 12
        iconSize: 22.0, // Reduced from default 24
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
