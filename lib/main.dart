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
import 'services/ebay_api_service.dart';  // Add this import
import 'services/ebay_search_service.dart';  // Add this import
import 'utils/logger.dart';
import 'services/battle_service.dart'; // Add the import for BattleService

void main() async {
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.e('Flutter error: ${details.exception}', 
        error: details.exception, 
        stackTrace: details.stack);
  };

  // Configure Logger - update this line to control logging
  AppLogger.logLevel = 2; // Show only INFO level and above (remove many debug messages)
  // AppLogger.quietMode(); // Uncomment this to see only warnings and errors
  // AppLogger.disableLogging(); // Uncomment this to disable all logs

  AppLogger.i('Flutter app starting...'); // This will still show

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('Flutter app starting...');
    
    // Initialize services first with proper constructors
    final storageService = await StorageService.init(null); // Changed from initialize() to init()
    final authService = AuthService(); // Removed storageService parameter
    await authService.initialize(); // Initialize after construction
    
    final tcgApiService = TcgApiService();
    final collectionService = await CollectionService.getInstance();
    final scannerService = ScannerService();
    final purchaseService = PurchaseService();
    await purchaseService.initialize();  // Make sure to initialize
    final ebayApiService = EbayApiService();
    final ebaySearchService = EbaySearchService();
    final battleService = BattleService(); // Add this line
    
    // Initialize providers with required parameters
    final appState = AppState(storageService, authService);
    final themeProvider = ThemeProvider();
    final currencyProvider = CurrencyProvider();
    final sortProvider = SortProvider();
    
    // Run app with providers properly set up
    runApp(
      MultiProvider(
        providers: [
          // ListenableProvider for services that extend ChangeNotifier
          ListenableProvider<PurchaseService>.value(value: purchaseService),
          ListenableProvider<EbaySearchService>.value(value: ebaySearchService),
          
          // Regular Provider for services that don't need updates
          Provider<StorageService>.value(value: storageService),
          Provider<AuthService>.value(value: authService),
          Provider<TcgApiService>.value(value: tcgApiService),
          Provider<CollectionService>.value(value: collectionService),
          Provider<ScannerService>.value(value: scannerService),
          Provider<EbayApiService>.value(value: ebayApiService),
          
          // Change this line from Provider to ChangeNotifierProvider
          ChangeNotifierProvider<BattleService>.value(value: battleService),
          
          // ChangeNotifierProvider for state management
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
          ChangeNotifierProvider<SortProvider>.value(value: sortProvider),
        ],
        child: const MyApp(),
      ),
    );
    
    debugPrint('App initialized with providers');
  }, (error, stack) {
    debugPrint('FATAL ERROR: $error');
    debugPrint('Stack trace: $stack');
  });
}

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
        // For '/search', we should return RootNavigator with initialTab set to 2
        '/search': (context) => const RootNavigator(initialTab: 2), // Update this to use named parameter
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
        '/add-to-collection': (context) => AddToCollectionScreen(
          card: ModalRoute.of(context)!.settings.arguments as TcgCard,
        ),
        '/home': (context) => const HomeScreen(),
        '/scanner': (context) => const ScannerScreen(),
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
