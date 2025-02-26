import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'services/navigation_service.dart';
import 'constants/colors.dart';
import 'constants/text_styles.dart';
import 'services/tcg_api_service.dart';
import 'services/auth_service.dart';
import 'providers/currency_provider.dart';
import 'services/purchase_service.dart';
import 'screens/splash_screen.dart';
import 'services/scanner_service.dart';
import 'screens/add_to_collection_screen.dart';
import 'screens/card_details_screen.dart';
import 'models/tcg_card.dart';
import 'services/collection_service.dart';
import 'screens/home_screen.dart';
import 'providers/sort_provider.dart';
import 'utils/string_extensions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the TcgApiService at app start
  TcgApiService();
  
  final collectionService = await CollectionService.getInstance();
  await collectionService.initializeLastUser(); // Add this line

  final purchaseService = PurchaseService();
  await purchaseService.initialize();
  
  final storageService = await StorageService.init(purchaseService);
  final authService = AuthService();
  final appState = AppState(storageService, authService);
  final scannerService = ScannerService();  // Create instance here
  
  await appState.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<PurchaseService>.value(value: purchaseService),
        ChangeNotifierProvider.value(value: appState),
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>.value(value: authService),
        Provider<ScannerService>.value(value: scannerService),  // Use .value constructor
        
        // Feature providers
        Provider<TcgApiService>(create: (_) => TcgApiService()),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (_) => CurrencyProvider(),
        ),
        // Add this provider
        ChangeNotifierProvider(
          create: (_) => SortProvider(),
        ),
      ],
      child: const CardWizzApp(),  // Remove the Builder widget
    ),
  );
}

class CardWizzApp extends StatelessWidget {
  const CardWizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey, // Use NavigationService.navigatorKey
          title: 'CardWizz',
          debugShowCheckedModeBanner: false,
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
              background: AppColors.background,
              error: AppColors.error,
              onPrimary: AppColors.onPrimary,
              onSecondary: AppColors.onSecondary,
              onSurface: AppColors.onSurface,
              onBackground: AppColors.onBackground,
            ),
            textTheme: TextTheme(
              titleLarge: TextStyle(color: AppColors.text),
              titleMedium: TextStyle(color: AppColors.text),
              bodyLarge: TextStyle(color: AppColors.text),
              bodyMedium: TextStyle(color: AppColors.text),
              labelLarge: TextStyle(color: AppColors.text),
              labelMedium: TextStyle(color: AppColors.text),
              displayLarge: TextStyle(color: AppColors.text),
              displayMedium: TextStyle(color: AppColors.text),
              displaySmall: TextStyle(color: AppColors.text),
            ),
            useMaterial3: true,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.text,
              elevation: 0,
              centerTitle: false,
              toolbarHeight: 44, // Even smaller height
              titleSpacing: 16, // Changed back to 16
              iconTheme: IconThemeData(
                size: 24, // Back to standard size for menu icon
                color: AppColors.text,
              ),
              // Removed actionsIconTheme since we don't need it anymore
            ),
            cardTheme: CardTheme(
              color: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: AppColors.primary.withOpacity(0.04),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppColors.primary,
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.pressed)) {
                    return AppColors.primary.withOpacity(0.9);
                  }
                  return AppColors.primary;
                }),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            iconTheme: const IconThemeData(
              color: AppColors.text,
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.text.withOpacity(0.5),  // Make unselected more visible
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,  // Increased from w600 to w700
                letterSpacing: 0.5,  // Add letter spacing
                height: 1.5,  // Increased from 1.0
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.text.withOpacity(0.8),  // Make unselected text more visible
                height: 1.5,
              ),
              type: BottomNavigationBarType.fixed,
              showUnselectedLabels: true,  // Make sure unselected labels are visible
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            useMaterial3: true,
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
            ),
          ),
          locale: appState.locale,
          supportedLocales: AppState.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/', // Add this line
          routes: {
            '/': (context) => const SplashScreen(),
            ...AppRoutes.routes,
            '/card-details': (context) => CardDetailsScreen(
              card: ModalRoute.of(context)!.settings.arguments as TcgCard,
            ),
            '/add-to-collection': (context) => AddToCollectionScreen(
              card: ModalRoute.of(context)!.settings.arguments as TcgCard,
            ),
            '/home': (context) => const HomeScreen(),  // Remove initialTab parameter
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
      },
    );
  }
}
