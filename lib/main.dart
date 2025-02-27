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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Initialize the TcgApiService at app start
  TcgApiService();
  
  final collectionService = await CollectionService.getInstance();
  await collectionService.initializeLastUser();

  final purchaseService = PurchaseService();
  await purchaseService.initialize();
  
  final storageService = await StorageService.init(purchaseService);
  final authService = AuthService();
  final appState = AppState(storageService, authService);
  final scannerService = ScannerService();  // Create instance here
  final themeProvider = ThemeProvider(); // Create theme provider
  
  await appState.initialize();
  // Wait for theme provider to initialize
  await Future.doWhile(() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return !themeProvider.isInitialized;
  });

  runApp(
    MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<PurchaseService>.value(value: purchaseService),
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: themeProvider), // Add theme provider
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        Provider<ScannerService>.value(value: scannerService),
        
        // Feature providers
        Provider<TcgApiService>(create: (_) => TcgApiService()),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (_) => CurrencyProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SortProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get providers
    final appState = Provider.of<AppState>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
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
        '/search': (context) => const SearchScreen(),
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
