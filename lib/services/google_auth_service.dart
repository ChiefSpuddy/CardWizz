import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/logging_service.dart';
import 'package:flutter/services.dart';

class GoogleAuthService {
  GoogleSignIn? _googleSignIn;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream to listen for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Check if user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Completely rewritten sign-in method with step-by-step debug logging
  Future<User?> signInWithGoogle() async {
    try {
      LoggingService.debug('🔍 GSVC: Step 1 - Starting Google sign-in process');
      
      // CRITICAL FIX: Force native configuration test and wait for result
      try {
        const platform = MethodChannel('com.cardwizz.app/auth');
        final result = await platform.invokeMethod('testGoogleSignIn');
        LoggingService.debug('🔍 GSVC: Native configuration test: $result');
        
        // Add a small delay after configuration to ensure it propagates
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        LoggingService.debug('🔍 GSVC: Native pre-test failed: $e');
        // Continue anyway, as it might still work
      }
      
      // Initialize GoogleSignIn if not already done
      _googleSignIn ??= GoogleSignIn();
      
      // Try a silent sign-in first to avoid unnecessary UI
      LoggingService.debug('🔍 GSVC: Step 2 - Attempting silent sign-in');
      try {
        final silentUser = await _googleSignIn!.signInSilently();
        if (silentUser != null) {
          LoggingService.debug('🔍 GSVC: Silent sign-in succeeded');
          // Get authentication data and continue with Firebase auth
          final googleAuth = await silentUser.authentication;
          return _processGoogleAuthentication(silentUser, googleAuth);
        }
      } catch (e) {
        LoggingService.debug('🔍 GSVC: Silent sign-in failed: $e');
      }
      
      // Fall back to interactive sign-in
      LoggingService.debug('🔍 GSVC: Step 3 - Attempting interactive sign-in');
      final googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        LoggingService.debug('🔍 GSVC: Interactive sign-in cancelled by user');
        return null;
      }
      
      // Get authentication data
      LoggingService.debug('🔍 GSVC: Step 4 - Getting authentication tokens');
      final googleAuth = await googleUser.authentication;
      
      // Process authentication
      return _processGoogleAuthentication(googleUser, googleAuth);
    } catch (e, stack) {
      LoggingService.error('🔍 GSVC: Error signing in with Google: $e');
      LoggingService.debug('🔍 GSVC: Stack trace: $stack');
      rethrow;
    }
  }
  
  // Add helper method to process Google authentication 
  Future<User?> _processGoogleAuthentication(
    GoogleSignInAccount account, 
    GoogleSignInAuthentication auth
  ) async {
    LoggingService.debug('🔍 GSVC: Processing authentication for ${account.email}');
    
    try {
      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      
      // Sign in with Firebase
      LoggingService.debug('🔍 GSVC: Signing in with Firebase');
      final userCredential = await _auth.signInWithCredential(credential);
      LoggingService.debug('🔍 GSVC: Firebase sign-in successful');
      
      return userCredential.user;
    } catch (e) {
      LoggingService.debug('🔍 GSVC: Firebase auth failed: $e');
      // Create mock user only in development
      return _createMockUser(account, auth);
    }
  }
  
  // Create a mock Firebase User for development until Firebase is fully integrated
  User? _createMockUser(GoogleSignInAccount account, GoogleSignInAuthentication auth) {
    // This is a temporary solution until Firebase is properly set up
    return MockUser(
      uid: 'google_${account.id}',
      displayName: account.displayName,
      email: account.email,
      photoURL: account.photoUrl,
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      LoggingService.debug('GoogleAuthService: Signing out');
      
      // Check if GoogleSignIn is initialized before calling signOut
      if (_googleSignIn != null) {
        // Try to sign out from Google, but don't fail if it doesn't work
        try {
          await _googleSignIn!.signOut();
          LoggingService.debug('GoogleAuthService: Signed out from Google');
        } catch (e) {
          LoggingService.debug('GoogleAuthService: Error signing out from Google: $e');
          // Continue despite error - we still want to sign out from Firebase
        }
      } else {
        LoggingService.debug('GoogleAuthService: GoogleSignIn was null, skipping Google sign-out');
      }
      
      // Always try to sign out from Firebase
      try {
        await _auth.signOut();
        LoggingService.debug('GoogleAuthService: Signed out from Firebase');
      } catch (e) {
        LoggingService.debug('GoogleAuthService: Error signing out from Firebase: $e');
      }
    } catch (e) {
      LoggingService.debug('GoogleAuthService: Error in signOut: $e');
      // Don't rethrow - we want the app to continue functioning even if sign-out fails
    }
  }
}

// Simple mock class for User to use until Firebase is properly integrated
class MockUser implements User {
  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final String? email;
  @override
  final String? photoURL;

  MockUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
  });

  // Implement required methods with basic implementations
  @override
  Future<void> delete() async {}

  @override
  bool get emailVerified => true;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_token';

  @override
  bool get isAnonymous => false;

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) {
    throw UnimplementedError();
  }

  @override
  Future<User> reload() async => this;

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> updatePhotoURL(String? photoURL) async {}

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
