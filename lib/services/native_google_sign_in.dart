import 'package:flutter/services.dart';
import '../services/logging_service.dart';

class NativeGoogleSignIn {
  static const MethodChannel _channel = MethodChannel('com.cardwizz.google_sign_in');
  static bool _initialized = false;
  
  static Future<void> init(String clientId) async {
    if (_initialized) return;
    
    try {
      LoggingService.debug('🔍 NATIVE: Initializing Google Sign-In with client ID');
      final result = await _channel.invokeMethod('init', {'clientId': clientId});
      LoggingService.debug('🔍 NATIVE: Initialization result: $result');
      _initialized = result == true;
    } catch (e) {
      LoggingService.error('🔍 NATIVE: Failed to initialize Google Sign-In: $e');
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>?> signIn() async {
    try {
      LoggingService.debug('🔍 NATIVE: Starting Google Sign-In');
      
      // Make sure we're initialized
      if (!_initialized) {
        await init('335432222368-is4qnf4cj3bhmp8jr6098dr82de76h8q.apps.googleusercontent.com');
      }
      
      final result = await _channel.invokeMethod('signIn');
      LoggingService.debug('🔍 NATIVE: Sign-in result: $result');
      
      if (result == null) {
        return null; // User cancelled
      }
      
      return Map<String, dynamic>.from(result);
    } catch (e) {
      LoggingService.error('🔍 NATIVE: Error during Google Sign-In: $e');
      rethrow;
    }
  }
  
  static Future<void> signOut() async {
    try {
      await _channel.invokeMethod('signOut');
      LoggingService.debug('🔍 NATIVE: Signed out from Google');
    } catch (e) {
      LoggingService.error('🔍 NATIVE: Error signing out from Google: $e');
      rethrow;
    }
  }
}
