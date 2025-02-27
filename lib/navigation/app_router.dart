// ...existing imports...
import '../screens/scanner_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ...existing routes...
      case '/scanner':
        return MaterialPageRoute(
          builder: (_) => const ScannerScreen(),
          settings: settings,
        );
      // ...existing routes...
    }
  }
}
