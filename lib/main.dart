import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'services/navigation_service.dart';
import 'constants/text_styles.dart';
import 'services/tcg_api_service.dart';
import 'services/auth_service.dart';
import 'providers/currency_provider.dart';
import 'providers/theme_provider.dart'; 
import 'services/purchase_service.dart';
import 'screens/splash_screen.dart';
import 'services/scanner_service.dart';
import 'screens/add_to_collection_screen.dart';
import 'screens/card_details_screen.dart';
import 'screens/search_screen.dart';
import 'screens/root_navigator.dart';
import 'models/tcg_card.dart';
import 'services/collection_service.dart';
import 'screens/home_screen.dart';
import 'providers/sort_provider.dart';
import 'utils/string_extensions.dart';
import 'constants/app_colors.dart';
import 'screens/scanner_screen.dart';
import 'services/ebay_api_service.dart';
import 'services/ebay_search_service.dart';
import 'utils/logger.dart';
import 'screens/loading_screen.dart';
import 'utils/create_card_back.dart';
import 'package:flutter/animation.dart';
import 'services/premium_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/collections_screen.dart';
import 'services/firebase_service.dart';
import 'screens/profile_screen.dart';
import 'screens/analytics_screen.dart';
import 'services/logging_service.dart'; // Add this import for LoggingService

// The simplest possible main function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  
  // Start with just the loading screen
  runApp(const SimpleLoadingApp());
  
  // Initialize the actual app behind the scenes
  _initializeAppInBackground(prefs);
}

// A clean, separate function to handle initialization with transition
Future<void> _initializeAppInBackground(SharedPreferences prefs) async {
  try {
    // Shorter initial delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Initialize Firebase first
    await FirebaseService.initialize();
    
    // Initialize services
    final storageService = await StorageService.init(null);
    final authService = AuthService();
    await authService.initialize();
    
    // Prepare other services
    final tcgApiService = TcgApiService();
    final collectionService = await CollectionService.getInstance();
    final scannerService = ScannerService();
    final purchaseService = PurchaseService();
    await purchaseService.initialize();
    final ebayApiService = EbayApiService();
    final ebaySearchService = EbaySearchService();
    
    // Initialize providers
    final appState = AppState(storageService, authService);
    final themeProvider = ThemeProvider();
    final currencyProvider = CurrencyProvider();
    final sortProvider = SortProvider();
    
    // Create the full app widget for transition
    final fullApp = MultiProvider(
      providers: [
        ListenableProvider<PurchaseService>.value(value: purchaseService),
        ListenableProvider<EbaySearchService>.value(value: ebaySearchService),
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        Provider<TcgApiService>.value(value: tcgApiService),
        Provider<CollectionService>.value(value: collectionService),
        ChangeNotifierProvider<ScannerService>.value(value: scannerService),
        Provider<EbayApiService>.value(value: ebayApiService),
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
        ChangeNotifierProvider<SortProvider>.value(value: sortProvider),
        ChangeNotifierProvider<PurchaseService>(
          create: (context) => PurchaseService(),
        ),
        ChangeNotifierProxyProvider<PurchaseService, PremiumService>(
          create: (context) => PremiumService(
            Provider.of<PurchaseService>(context, listen: false),
            prefs,
          ),
          update: (context, purchaseService, previous) => 
            previous ?? PremiumService(purchaseService, prefs),
        ),
      ],
      child: const MyApp(),
    );
    
    // Run the full app with a beautiful transition
    runApp(AppTransition(child: fullApp));
    
  } catch (e, stack) {
    debugPrint('Error during initialization: $e');
    debugPrint(stack.toString());
  }
}

// Simple app that ONLY shows the loading screen with animated progress
class SimpleLoadingApp extends StatefulWidget {
  const SimpleLoadingApp({Key? key}) : super(key: key);

  @override
  State<SimpleLoadingApp> createState() => _SimpleLoadingAppState();
}

class _SimpleLoadingAppState extends State<SimpleLoadingApp> {
  double _simulatedProgress = 0.0;
  String _loadingMessage = 'Starting CardWizz...';
  late Timer _progressTimer;
  final List<String> _loadingMessages = [
    'Starting CardWizz...',
    'Loading resources...',
    'Getting things ready...',
    'Finalizing...',  // Reduced number of messages for faster loading
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    // Update progress every 50ms instead of 80ms for faster animation
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_simulatedProgress < 0.95) {
        setState(() {
          // Increase increments for faster progress
          double increment = 0.015;  // Was 0.01
          if (_simulatedProgress > 0.7) {
            increment = 0.01;  // Was 0.005
          } else if (_simulatedProgress < 0.2) {
            increment = 0.025;  // Was 0.015
          }
          
          _simulatedProgress += increment;
          
          // Update messages more frequently (every 15 ticks instead of 25)
          if (_simulatedProgress > 0.2 && 
              _simulatedProgress < 0.9 && 
              timer.tick % 15 == 0 && 
              _messageIndex < _loadingMessages.length - 1) {
            _messageIndex++;
            _loadingMessage = _loadingMessages[_messageIndex];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _progressTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.blue.shade700,
          secondary: Colors.lightBlue,
          surface: Colors.white,
          background: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade300,
          secondary: Colors.lightBlue,
          surface: const Color(0xFF121212),
          background: const Color(0xFF121212),
        ),
      ),
      // Use system brightness to match the device theme
      themeMode: ThemeMode.system,
      home: LoadingScreen(
        progress: _simulatedProgress,
        message: _loadingMessage,
      ),
    );
  }
}

// The rest of your code...

// Debug wrapper to catch early startup issues
class AppStartupDebugWrapper extends StatefulWidget {
  const AppStartupDebugWrapper({Key? key}) : super(key: key);

  @override
  State<AppStartupDebugWrapper> createState() => _AppStartupDebugWrapperState();
}

class _AppStartupDebugWrapperState extends State<AppStartupDebugWrapper> {
  bool _isLoading = true;
  String _status = 'Starting app...';
  Object? _error;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      setState(() => _status = 'Initializing services...');
      
      // Initialize any required services here
      // For example: await Firebase.initializeApp();
      
      setState(() => _status = 'Starting app...');
      
      // Wait a moment to ensure logs are visible
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e;
        _status = 'Error during initialization';
      });
      debugPrint('Error during app initialization: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show simple loading screen
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(_status),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text('Error: $_error', 
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ]
              ],
            ),
          ),
        ),
      );
    }
    
    // Launch your actual app
    return YourActualApp();
  }
}

// Replace this with your actual app
class YourActualApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Return your actual MyApp widget here
    return MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get providers
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Ensure proper status bar visibility based on current theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        themeProvider.isDarkMode
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      );
    });
    
    return MaterialApp(
      title: 'CardWizz',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentThemeData.copyWith(brightness: Brightness.light),
      darkTheme: themeProvider.currentThemeData.copyWith(brightness: Brightness.dark),
      themeMode: themeProvider.themeMode,
      navigatorKey: NavigationService.navigatorKey,
      locale: appState.locale,
      supportedLocales: AppState.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const RootNavigator(),
        '/search': (context) => const RootNavigator(initialTab: 2),
        '/card': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final card = args?['card'] as TcgCard?;
          if (card == null) {
            return const SearchScreen();
          }
          return CardDetailsScreen(
            card: card,
            heroContext: args?['heroContext'] ?? 'search',
          );
        },
        // Add an explicit route for card-details
        '/card-details': (context) {
          final card = ModalRoute.of(context)?.settings.arguments as TcgCard;
          LoggingService.debug('Direct card-details route activated for: ${card.name}');
          return CardDetailsScreen(
            card: card,
            heroContext: 'direct',
          );
        },
        '/add-to-collection': (context) => AddToCollectionScreen(
          card: ModalRoute.of(context)!.settings.arguments as TcgCard,
        ),
        '/home': (context) => const HomeScreen(),
        '/scanner': (context) => const ScannerScreen(),
        '/collection': (context) => const CollectionsScreen(showEmptyState: true),
        '/profile': (context) => const ProfileScreen(), 
        '/analytics': (context) => const AnalyticsScreen(), // Add the analytics route
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/card-details') {
          return MaterialPageRoute(
            builder: (context) => CardDetailsScreen(
              card: settings.arguments as TcgCard,
            ),
          );
        } else if (settings.name == '/add-to-collection') {
          return MaterialPageRoute(
            builder: (context) => AddToCollectionScreen(
              card: settings.arguments as TcgCard,
            ),
          );
        }
        return null;
      },
    );
  }
}

// New class for handling the transition animation
class AppTransition extends StatefulWidget {
  final Widget child;
  
  const AppTransition({Key? key, required this.child}) : super(key: key);
  
  @override
  State<AppTransition> createState() => _AppTransitionState();
}

class _AppTransitionState extends State<AppTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Create animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Create scale animation
    _scaleAnimation = Tween<double>(begin: 1.05, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Start animation after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
