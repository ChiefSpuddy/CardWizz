import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../providers/app_state.dart';
import '../widgets/sign_in_view.dart';
import 'home_overview.dart';
import 'search_screen.dart';
import 'root_navigator.dart';
import '../widgets/standard_app_bar.dart';
import './collections_screen.dart';  // Update this import

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
  
  // Update this method to use the public switchToTab method instead of private _RootNavigatorState
  void setSelectedIndex(int index) {
    // Use the public static method instead of trying to access the private state
    RootNavigator.switchToTab(context, index);
  }

  void goToSearchWithQuery(String query) {
    RootNavigator.switchToTab(context, 2); // 2 is the index for Search tab
    
    // Small delay to ensure the search screen is initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      SearchScreen.startSearch(context, query);
    });
  }

  void _onScroll() {
    // Add scroll handling logic here if needed
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading('Features'),
        SizedBox(
          height: 110,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              // ...existing feature items...
              // Card Arena feature card removed
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String description,
    bool isNew = false,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    RootNavigator.switchToTab(context, index);
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication status before building HomeScreen
    final isSignedIn = Provider.of<AppState>(context).isAuthenticated;
    
    // If not signed in, return the SignInView directly
    if (!isSignedIn) {
      return const SignInView(showNavigationBar: false);
    }
    
    // Only continue with Scaffold if authenticated
    return Scaffold(
      key: _scaffoldKey,
      appBar: StandardAppBar(
        title: 'CardWizz', // Keep app name instead of 'Home'
        onLeadingPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: const AppDrawer(),
      body: const HomeOverview(), // HomeOverview already has no Scaffold, it just returns content
    );
  }
}
