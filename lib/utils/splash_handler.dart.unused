import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../utils/logger.dart';

class SplashHandler {
  static bool _preserved = false;
  static bool _removed = false;
  static final ValueNotifier<bool> isRemoved = ValueNotifier<bool>(false);
  
  /// Call this early in app startup to preserve the native splash screen
  /// until Flutter is ready to draw its first frame
  static void preserve() {
    try {
      FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
      _preserved = true;
      _removed = false;
      isRemoved.value = false;
      AppLogger.d('Native splash screen preserved', tag: 'Splash');
    } catch (e) {
      AppLogger.e('Error preserving splash screen: $e', tag: 'Splash', error: e);
    }
  }
  
  /// Call this when your Flutter UI is ready to be displayed
  static Future<void> remove({Duration delay = const Duration(milliseconds: 300)}) async {
    if (_preserved && !_removed) {
      try {
        // Wait for Flutter to render a frame
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Make sure our custom loading screen is ready before removing splash
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Add a small delay before removing splash
          await Future.delayed(delay);
          
          // Now actually remove the native splash
          FlutterNativeSplash.remove();
          _removed = true;
          isRemoved.value = true;
          AppLogger.d('Native splash screen removed', tag: 'Splash');
        });
      } catch (e) {
        AppLogger.e('Error removing splash screen: $e', tag: 'Splash', error: e);
      }
    }
  }
}
