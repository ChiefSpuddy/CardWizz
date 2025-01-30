import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';  // Add this import
import 'package:provider/provider.dart';
import 'routes.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'constants/colors.dart';
import 'constants/text_styles.dart';
import 'services/tcg_api_service.dart';
import 'services/auth_service.dart'; // Add this import
import 'providers/currency_provider.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final purchaseService = PurchaseService();
  await purchaseService.initialize();
  
  final storageService = await StorageService.init(purchaseService);
  final authService = AuthService();
  final appState = AppState(storageService, authService);
  
  await appState.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<PurchaseService>.value(value: purchaseService),
        ChangeNotifierProvider.value(value: appState),
        Provider<StorageService>.value(value: storageService),  // Changed this line
        Provider<AuthService>.value(value: authService),
        
        // Feature providers
        Provider<TcgApiService>(create: (_) => TcgApiService()),
        ChangeNotifierProvider<CurrencyProvider>(
          create: (_) => CurrencyProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Verify provider is accessible
          final purchaseService = Provider.of<PurchaseService>(context, listen: false);
          print('PurchaseService initialized: ${purchaseService.isLoading}');
          return const CardWizzApp();
        },
      ),
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
              backgroundColor: Colors.white,
              foregroundColor: AppColors.text,
              elevation: 0,
              centerTitle: true,
              scrolledUnderElevation: 0,
              shape: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
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
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
          navigatorKey: GlobalKey<NavigatorState>(),
          builder: (context, child) {
            if (appState.isLoading) {
              return const MaterialApp(
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            return child!;
          },
        );
      },
    );
  }
}
