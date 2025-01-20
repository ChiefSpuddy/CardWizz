import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
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
