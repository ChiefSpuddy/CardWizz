import 'package:flutter/material.dart';
import 'screens/profile_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/search_screen.dart';
import 'screens/collections_screen.dart'; // Note: renamed from collection_screen.dart
import 'screens/home_screen.dart';
import 'package:intl/intl.dart';
import 'providers/currency_provider.dart'; // Fixed path
import 'package:provider/provider.dart';

class RootNavigator extends StatefulWidget {
  const RootNavigator({
    Key? key,
    this.initialTab = 0,
  }) : super(key: key);

  final int initialTab;

  @override
  State<RootNavigator> createState() => RootNavigatorState();
}

class RootNavigatorState extends State<RootNavigator> {
  late int _selectedIndex;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  void switchToTab(int index) {
    _onNavigationItemTapped(index);
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab =
            !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_selectedIndex != 0) {
            _onNavigationItemTapped(0);
            return false;
          }
        }
        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildOffstageNavigator(0),
            _buildOffstageNavigator(1),
            _buildOffstageNavigator(2),
            _buildOffstageNavigator(3),
            _buildOffstageNavigator(4),
            _buildOffstageNavigator(5),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavigationItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'Collection',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_a_photo),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: TabNavigator(
        navigatorKey: _navigatorKeys[index],
        tabIndex: index,
      ),
    );
  }
}

class TabNavigator extends StatelessWidget {
  const TabNavigator({
    required this.navigatorKey,
    required this.tabIndex,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (tabIndex == 0) {
      child = const HomeScreen();
    } else if (tabIndex == 1) {
      child = const CollectionsScreen(); // Changed from CollectionScreen
    } else if (tabIndex == 2) {
      child = const SearchScreen();
    } else if (tabIndex == 3) {
      child = const ScannerScreen();
    } else if (tabIndex == 4) {
      child = const AnalyticsScreen();
    } else if (tabIndex == 5) {
      child = const ProfileScreen();
    } else {
      child = const SizedBox.shrink();
    }

    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }
}