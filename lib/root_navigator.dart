















































































































































































}  }    );      },        );          builder: (context) => child,        return MaterialPageRoute(      onGenerateRoute: (routeSettings) {      key: navigatorKey,    return Navigator(    }      child = const SizedBox.shrink();    } else {      child = const CardArenaScreen(); // Add the Card Arena screen    } else if (tabIndex == 6) {      child = const ProfileScreen();    } else if (tabIndex == 5) {      child = const AnalyticsScreen();    } else if (tabIndex == 4) {      child = const ScannerScreen();    } else if (tabIndex == 3) {      child = const SearchScreen();    } else if (tabIndex == 2) {      child = const CollectionScreen();    } else if (tabIndex == 1) {      child = const HomeScreen();    if (tabIndex == 0) {    Widget child;  Widget build(BuildContext context) {  @override  });    required this.tabIndex,    required this.navigatorKey,  const TabNavigator({    final int tabIndex;  final GlobalKey<NavigatorState> navigatorKey;class TabNavigator extends StatelessWidget {}  }    );      ),        tabIndex: index,        navigatorKey: _navigatorKeys[index],      child: TabNavigator(      offstage: _selectedIndex != index,    return Offstage(  Widget _buildOffstageNavigator(int index) {  }    );      ),        ),          ],            ),              label: 'Arena',              icon: Icon(Icons.sports_kabaddi),            BottomNavigationBarItem(            ),              label: 'Profile',              icon: Icon(Icons.account_circle),            BottomNavigationBarItem(            ),              label: 'Analytics',              icon: Icon(Icons.analytics),            BottomNavigationBarItem(            ),              label: 'Scan',              icon: Icon(Icons.add_a_photo),            BottomNavigationBarItem(            ),              label: 'Search',              icon: Icon(Icons.search),            BottomNavigationBarItem(            ),              label: 'Collection',              icon: Icon(Icons.library_books),            BottomNavigationBarItem(            ),              label: 'Home',              icon: Icon(Icons.home),            BottomNavigationBarItem(          items: const [          unselectedLabelStyle: TextStyle(fontSize: 12),          selectedLabelStyle: TextStyle(fontSize: 12),          type: BottomNavigationBarType.fixed,          onTap: _onNavigationItemTapped,          currentIndex: _selectedIndex,        bottomNavigationBar: BottomNavigationBar(        ),          ],            _buildOffstageNavigator(6), // Add Card Arena tab            _buildOffstageNavigator(5),            _buildOffstageNavigator(4),            _buildOffstageNavigator(3),            _buildOffstageNavigator(2),            _buildOffstageNavigator(1),            _buildOffstageNavigator(0),          children: [        body: Stack(      child: Scaffold(      },        return isFirstRouteInCurrentTab;        }          }            return false;            _onNavigationItemTapped(0);          if (_selectedIndex != 0) {        if (isFirstRouteInCurrentTab) {            !await _navigatorKeys[_selectedIndex].currentState!.maybePop();        final isFirstRouteInCurrentTab =       onWillPop: () async {    return WillPopScope(  Widget build(BuildContext context) {  @override  }    });      _selectedIndex = index;    setState(() {  void _onNavigationItemTapped(int index) {  }    _onNavigationItemTapped(index);  void switchToTab(int index) {  // Method to allow other widgets to programmatically switch tabs    }    _selectedIndex = widget.initialTab;    super.initState();  void initState() {  @override  ];    GlobalKey<NavigatorState>(), // Add key for Card Arena tab    GlobalKey<NavigatorState>(),    GlobalKey<NavigatorState>(),    GlobalKey<NavigatorState>(),    GlobalKey<NavigatorState>(),    GlobalKey<NavigatorState>(),    GlobalKey<NavigatorState>(),  final List<GlobalKey<NavigatorState>> _navigatorKeys = [  late int _selectedIndex;class RootNavigatorState extends State<RootNavigator> {}  State<RootNavigator> createState() => RootNavigatorState();  @override  }) : super(key: key);    this.initialTab = 0,    Key? key,  const RootNavigator({    final int initialTab;class RootNavigator extends StatefulWidget {import 'card_arena_screen.dart';import 'profile_screen.dart';import 'analytics_screen.dart';import 'scanner_screen.dart';import 'search_screen.dart';import 'collection_screen.dart';import 'home_screen.dart';import 'package:intl/intl.dart';import '../widgets/animated_background.dart';import '../models/battle_stats.dart'; // This import is fine now that we removed duplicatesimport '../models/battle_result.dart';import '../providers/currency_provider.dart';import 'package:provider/provider.dart';import 'package:flutter/material.dart';// Update to include the Card Arena tab