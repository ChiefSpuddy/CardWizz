import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'services/logging_service.dart'; 

void main() async {
  try {
    // Initialize Flutter binding
    WidgetsFlutterBinding.ensureInitialized();
    
    // CRITICAL FIX: Initialize Firebase first, synchronously
    await Firebase.initializeApp();
    LoggingService.debug('Firebase initialized successfully');
    
    // Set up NavigationService
    NavigationService.navigatorKey = GlobalKey<NavigatorState>();
    
    // Create a simple loading screen key - don't use static properties
    final loadingScreenKey = GlobalKey<_SimpleLoadingAppState>();
    
    // Initialize SharedPreferences - this is critical
    final prefs = await SharedPreferences.getInstance();
    
    // Start with loading screen
    runApp(SimpleLoadingApp(key: loadingScreenKey));
    
    // Continue initialization in background
    _initializeApp(prefs, loadingScreenKey);
  } catch (e, stack) {
    // Last resort exception handling
    debugPrint('Error during app startup: $e');
    debugPrint(stack.toString());
    
    // Fall back to a very simple app with error message
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start app',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text('Please restart the app', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// More reliable initialization function
Future<void> _initializeApp(
  SharedPreferences prefs, 
  GlobalKey<_SimpleLoadingAppState> loadingScreenKey
) async {
  try {
    // Brief delay to allow loading screen to render
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Initialize core services directly (no parallel for simplicity)
    final storageService = await StorageService.init(null);
    final authService = AuthService();
    await authService.initialize();
    
    // Create core providers
    final appState = AppState(storageService, authService);
    final themeProvider = ThemeProvider();
    final currencyProvider = CurrencyProvider();
    final sortProvider = SortProvider();
    
    // CRITICAL FIX: Initialize PurchaseService during main initialization
    final purchaseService = PurchaseService();
    await purchaseService.initialize();
    
    // CRITICAL FIX: Make PremiumService available globally
    final premiumService = await PremiumService.initialize(purchaseService, prefs);
    
    // CRITICAL FIX: Initialize CollectionService directly instead of using FutureProvider
    final collectionService = await CollectionService.getInstance();
    
    // Signal loading screen that initialization is complete
    try {
      final loadingState = loadingScreenKey.currentState;
      if (loadingState != null) {
        loadingState.signalInitComplete();
      }
    } catch (e) {
      LoggingService.debug('Non-critical error signaling loading screen: $e');
    }
    
    // Create remaining services immediately
    final tcgApiService = TcgApiService();
    final scannerService = ScannerService();
    final ebayApiService = EbayApiService();
    final ebaySearchService = EbaySearchService();
    
    // Set up the full MultiProvider for the app
    final fullApp = MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
        ChangeNotifierProvider<SortProvider>.value(value: sortProvider),
        ChangeNotifierProvider<PurchaseService>.value(value: purchaseService),
        // CRITICAL FIX: Use ChangeNotifierProvider for PremiumService to ensure updates propagate
        ChangeNotifierProvider<PremiumService>.value(value: premiumService),
        Provider<CollectionService>.value(value: collectionService),
        Provider<TcgApiService>.value(value: tcgApiService),
        ChangeNotifierProvider<ScannerService>.value(value: scannerService),
        Provider<EbayApiService>.value(value: ebayApiService),
        ChangeNotifierProvider<EbaySearchService>.value(value: ebaySearchService),
      ],
      child: const MyApp(),
    );
    
    // Run the app with transition
    runApp(AppTransition(child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: fullApp,
    )));
    
    // No need to initialize background services again - we already have them
    LoggingService.debug('App initialization completed successfully');
    
  } catch (e, stack) {
    LoggingService.debug('Error during initialization: $e');
    LoggingService.debug(stack.toString());
    
    // Show a meaningful error screen
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CardWizz',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Please restart the application', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Move background task initialization to a separate function
Future<void> _initializeBackgroundTasks(
  SharedPreferences prefs, 
  {PurchaseService? purchaseService,
  PremiumService? premiumService}
) async {
  try {
    // Initialize purchase service if not provided
    if (purchaseService == null) {
      purchaseService = PurchaseService();
      await purchaseService.initialize();
    }
    
    // Don't create a new PremiumService if one is already provided
    if (premiumService == null) {
      // Initialize premium service using the static factory method
      final newPremiumService = await PremiumService.initialize(purchaseService, prefs);
      LoggingService.debug('Created new PremiumService instance in background');
    } else {
      LoggingService.debug('Using existing PremiumService instance');
    }
    
    LoggingService.debug('Background services initialized successfully');
  } catch (e) {
    LoggingService.debug('Non-critical error initializing background services: $e');
  }
}

// Simple app that shows loading screen with animated progress
class SimpleLoadingApp extends StatefulWidget {
  const SimpleLoadingApp({Key? key}) : super(key: key);

  @override
  State<SimpleLoadingApp> createState() => _SimpleLoadingAppState();
}

class _SimpleLoadingAppState extends State<SimpleLoadingApp> {
  double _simulatedProgress = 0.0;
  String _loadingMessage = 'Starting CardWizz...';
  late Timer _progressTimer;
  bool _initCompleted = false;
  final List<String> _loadingMessages = [
    'Starting CardWizz...',
    'Loading resources...',
    'Getting things ready...',
    'Finalizing...',
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_simulatedProgress < 1.0) {
        setState(() {
          // Progress increments
          double increment = 0.015;
          if (_simulatedProgress > 0.7) {
            increment = 0.01;
          } else if (_simulatedProgress < 0.2) {
            increment = 0.025;
          }
          
          // Speed up when initialization is done
          if (_initCompleted && _simulatedProgress > 0.95) {
            increment = 0.05;
          }
          
          _simulatedProgress = (_simulatedProgress + increment).clamp(0.0, 1.0);
          
          // Update messages
          if (_simulatedProgress > 0.2 && 
              _simulatedProgress < 0.9 && 
              timer.tick % 15 == 0 && 
              _messageIndex < _loadingMessages.length - 1) {
            _messageIndex++;
            _loadingMessage = _loadingMessages[_messageIndex];
          }
          
          // Complete the timer when done
          if (_simulatedProgress >= 0.999) {
            timer.cancel();
          }
        });
      }
    });
  }

  void signalInitComplete() {
    setState(() => _initCompleted = true);
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
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade300,
          secondary: Colors.lightBlue,
        ),
      ),
      themeMode: ThemeMode.system,
      home: LoadingScreen(
        progress: _simulatedProgress,
        message: _loadingMessage,
      ),
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

// Simple NavigationService that doesn't need initialization
class NavigationService {
  // Use a direct global key instead of a static reference
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

// MyApp as before
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: true);
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
        // ...existing routes...
      },
      onGenerateRoute: (settings) {
        // ...existing onGenerateRoute logic...
        return null;
      },
    );
  }
}
