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

// Remove these imports - they're causing the error
// import 'package:flutter/widgets.dart' as widgets hide Hero;
// import 'package:flutter/material.dart' hide Hero;
// import 'widgets/no_hero.dart';

// Remove this Hero class definition
// class Hero extends NoHero { ... }

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Add error handler for Provider errors during disposal
    FlutterError.onError = (FlutterErrorDetails details) {
      // Ignore Provider access during disposal errors
      final exception = details.exception;
      if (exception is FlutterError && 
          exception.message.contains("Looking up a deactivated widget's ancestor is unsafe")) {
        debugPrint('Ignoring Provider error during disposal: ${exception.message}');
      } else {
        // Handle other errors normally
        FlutterError.presentError(details);
      }
    };
    
    debugPrint('Flutter app starting...');
    
    // Initialize services first with proper constructors
    final storageService = await StorageService.init(null);
    final authService = AuthService();
    await authService.initialize();
    
    final tcgApiService = TcgApiService();
    final collectionService = await CollectionService.getInstance();
    final scannerService = ScannerService();
    final purchaseService = PurchaseService();
    await purchaseService.initialize();
    final ebayApiService = EbayApiService();
    final ebaySearchService = EbaySearchService();
    
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
      
      // Just add this one line to disable Hero animations completely
      builder: (context, child) => HeroControllerScope.none(child: child ?? const SizedBox.shrink()),
      
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
