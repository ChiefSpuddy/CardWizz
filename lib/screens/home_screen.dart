import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'home_overview.dart';
import 'search_screen.dart';
import 'root_navigator.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const HomeScreen({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  static final _scrollController = ScrollController();
  
  static void scrollToTop(BuildContext context) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    HomeScreen._scrollController.addListener(_onScroll);
  }
  
  void setSelectedIndex(int index) {
    // Find RootNavigator and set its index
    final rootNavigator = context.findRootAncestorStateOfType<State<RootNavigator>>();
    if (rootNavigator != null) {
      (rootNavigator as dynamic)._onNavigationItemTapped(index);
    }
  }

  void goToSearchWithQuery(String query) {
    setSelectedIndex(2); // Switch to search tab
    
    // Small delay to ensure the search screen is initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      SearchScreen.startSearch(context, query);
    });
  }

  void _onScroll() {
    // Add scroll handling logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      // Don't use SingleChildScrollView here, the HomeOverview widget will handle its own scrolling
      body: const HomeOverview(),
    );
  }
}
