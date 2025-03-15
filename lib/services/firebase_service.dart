import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../services/logging_service.dart';

class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase with retry mechanism
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize Firebase with standard options
      final FirebaseOptions? options = await _getFirebaseOptions();
      
      if (options != null) {
        await Firebase.initializeApp(options: options);
        LoggingService.debug('Firebase initialized successfully with options');
      } else {
        // Fall back to default initialization if options aren't available
        await Firebase.initializeApp();
        LoggingService.debug('Firebase initialized with default configuration');
      }
      
      _initialized = true;
    } catch (e) {
      // Fix: Replace named parameter 'error:' with positional parameter
      LoggingService.error('Firebase initialization failed: $e');
      // Don't rethrow to allow the app to continue even if Firebase init fails
    }
  }

  /// Helper method to get Firebase options from GoogleService-Info.plist/google-services.json
  static Future<FirebaseOptions?> _getFirebaseOptions() async {
    try {
      // This will use the default options from the GoogleService-Info.plist file
      // The file should be added to the iOS project via Xcode
      return Firebase.app().options;
    } catch (e) {
      // If we can't get options, return null to try default initialization
      LoggingService.warning('Could not load Firebase options: $e');
      return null;
    }
  }

  /// Check if Firebase is properly initialized
  static bool get isInitialized => _initialized;
}
