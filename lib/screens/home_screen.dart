import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'home_overview.dart';
import 'search_screen.dart';
import 'root_navigator.dart';  // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  
  // Add these methods back that other screens are using
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

  @override
  void initState() {
    super.initState();
    HomeScreen._scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Add scroll handling logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        controller: HomeScreen._scrollController,
        slivers: [
          SliverFillRemaining(
            child: HomeOverview(),
          ),
        ],
      ),
    );
  }
}
