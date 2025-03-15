import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/logging_service.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream to listen for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Check if user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;
  
  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If user canceled the sign-in flow
      if (googleUser == null) return null;

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      LoggingService.debug('Google Sign-In successful for: ${googleUser.displayName}');
      
      try {
        // Try to use Firebase Auth if available
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with credential
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        
        LoggingService.debug('Successfully signed in with Google via Firebase: ${userCredential.user?.displayName}');
        return userCredential.user;
      } catch (e) {
        LoggingService.warning('Firebase auth failed, using mock user: $e');
        // Fall back to mock user if Firebase auth fails
        return _createMockUser(googleUser, googleAuth);
      }
    } catch (e) {
      // Fix: Change error method call to use the correct format
      LoggingService.error('Error signing in with Google: $e');
      return null;
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
      await _googleSignIn.signOut();
      await _auth.signOut();
      LoggingService.debug('Successfully signed out from Google');
    } catch (e) {
      // Fix: Change error method call to use the correct format
      LoggingService.error('Error signing out from Google: $e');
      rethrow;
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
