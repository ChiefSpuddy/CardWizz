import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'constants/colors.dart';
import 'constants/text_styles.dart';
import 'services/tcg_api_service.dart';  // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize storage service
  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(storageService)),
        Provider<StorageService>.value(value: storageService),
        Provider<TcgApiService>(create: (_) => TcgApiService()),  // Add this provider
      ],
      child: const CardWizzApp(),
    ),
  );
}

class CardWizzApp extends StatelessWidget {
  const CardWizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardWizz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          displayLarge: AppTextStyles.heading1,
          displayMedium: AppTextStyles.heading2,
          bodyLarge: AppTextStyles.body,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(AppColors.primary),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      navigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, child) {
        return Consumer<AppState>(
          builder: (context, appState, _) {
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
