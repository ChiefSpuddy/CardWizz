import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/scanner_screen.dart';
import '../screens/search_screen.dart';
import '../screens/collections_screen.dart';
import '../screens/home_screen.dart';
import 'package:intl/intl.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/navigation_service.dart'; // Add missing import
import '../services/logging_service.dart'; // Add missing import

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
  
  // Remove one key since we're removing Scanner from the nav bar
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Handle initial tab from route arguments if provided
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('initialTab')) {
      final requestedTab = args['initialTab'] as int;
      if (_selectedIndex != requestedTab) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedIndex = requestedTab);
          }
        });
      }
    }
  }

  // Make this method public and static
  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Keep this method in case there are direct calls to it
  void _onNavigationItemTapped(int index) {
    setSelectedIndex(index);
  }

  // Improve the static method to find and switch tabs from anywhere
  static void switchToTab(BuildContext context, int index) {
    LoggingService.debug('RootNavigator: Attempting to switch to tab $index');
    
    // Try multiple approaches to find the RootNavigatorState
    
    // First approach: Direct ancestor state lookup
    final state = context.findAncestorStateOfType<RootNavigatorState>();
    if (state != null) {
      LoggingService.debug('RootNavigator: Found state via findAncestorStateOfType');
      state.setSelectedIndex(index);
      return;
    }
    
    // Second approach: Navigate to route with specified tab
    try {
      LoggingService.debug('RootNavigator: Trying navigation to route with tab param');
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
        arguments: {'initialTab': index}
      );
      return;
    } catch (e) {
      LoggingService.debug('RootNavigator: Navigation error: $e');
    }
    
    // Third approach: Get global navigator context and try again
    try {
      final navigatorContext = NavigationService.navigatorKey.currentContext;
      if (navigatorContext != null) {
        final rootState = navigatorContext.findAncestorStateOfType<RootNavigatorState>();
        if (rootState != null) {
          LoggingService.debug('RootNavigator: Found state via NavigationService');
          rootState.setSelectedIndex(index);
          return;
        }
      }
    } catch (e) {
      LoggingService.debug('RootNavigator: NavigationService error: $e');
    }
    
    // Last resort: Schedule a callback after the frame
    LoggingService.debug('RootNavigator: Using post-frame callback');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final navigatorContext = NavigationService.navigatorKey.currentContext;
        if (navigatorContext != null) {
          Navigator.of(navigatorContext, rootNavigator: true).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
            arguments: {'initialTab': index}
          );
        }
      } catch (e) {
        LoggingService.debug('RootNavigator: Post-frame callback error: $e');
      }
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
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            _onNavigationItemTapped(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.6) 
              : Colors.black54,
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? AppColors.darkCardBackground 
              : Colors.white,
          elevation: 8,
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
      ),
    );
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) => _getScreenForIndex(index),
          );
        },
      ),
    );
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const CollectionsScreen(showEmptyState: true);
      case 2:
        return const SearchScreen();
      case 3:
        return const AnalyticsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }
  
  // Add a helper method to reset the navigator state when needed
  void resetToRoot(int index) {
    if (index >= 0 && index < _navigatorKeys.length) {
      final navigatorState = _navigatorKeys[index].currentState;
      if (navigatorState != null) {
        // Pop to first route
        while (navigatorState.canPop()) {
          navigatorState.pop();
        }
      }
    }
  }
}
