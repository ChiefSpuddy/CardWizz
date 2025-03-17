import '../services/logging_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/collection_service.dart';
import '../services/storage_service.dart';
import 'package:characters/characters.dart';
// Add import for Random
import 'dart:math';
import '../services/google_auth_service.dart';
import 'dart:async'; // Add this for StreamController
import 'package:firebase_auth/firebase_auth.dart'; // Add this import for AuthCredential

class AuthService {
  static const defaultUsername = 'Pokemon Trainer';
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  AuthUser? _currentUser;
  SharedPreferences? _prefs;
  late GoogleAuthService _googleAuthService;
  
  // Add stream controllers for auth state changes and errors
  final StreamController<AuthUser?> _authStateController = StreamController<AuthUser?>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get currentUser => _currentUser;

  AuthService() {
    _googleAuthService = GoogleAuthService();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('user_id');
    if (savedUserId != null) {
      _isAuthenticated = true;
      _currentUser = AuthUser(
        id: savedUserId,
        email: prefs.getString('${savedUserId}_email'),
        name: prefs.getString('${savedUserId}_name'),
        avatarPath: prefs.getString('${savedUserId}_avatar'),
        locale: prefs.getString('${savedUserId}_locale') ?? 'en',
        username: prefs.getString('${savedUserId}_username'),
        authProvider: prefs.getString('${savedUserId}_authProvider') ?? 'apple', // Add default authProvider
      );
      
      // Initialize CollectionService with saved user ID
      final collectionService = await CollectionService.getInstance();
      await collectionService.setCurrentUser(savedUserId);
    }
    _isInitialized = true;
  }

  Future<void> _saveUserData(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save all user data
    await prefs.setString('user_id', user.id);
    await prefs.setString('${user.id}_email', user.email ?? '');
    await prefs.setString('${user.id}_name', user.name ?? '');
    await prefs.setString('${user.id}_locale', user.locale ?? 'en');
    await prefs.setString('${user.id}_authProvider', user.authProvider ?? 'apple'); // Save authProvider
    
    // Save the full JSON data for easier restoration
    await prefs.setString('${user.id}_data', jsonEncode(user.toJson()));
    
    if (user.avatarPath != null) {
      await prefs.setString('${user.id}_avatar', user.avatarPath!);
    }
    if (user.username != null) {
      await prefs.setString('${user.id}_username', user.username!);
    }
    
    // Also store the userId in a central place
    await prefs.setString('current_user_id', user.id);
  }

  Future<void> updateAvatar(String avatarPath) async {
    if (_currentUser != null) {
      try {
        // Validate avatar path format
        if (!avatarPath.startsWith('assets/')) {
          LoggingService.debug('Invalid avatar path format: $avatarPath');
          return;
        }
        
        // Save the avatar path
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${_currentUser!.id}_avatar', avatarPath);
        _currentUser = _currentUser!.copyWith(avatarPath: avatarPath);
        
        LoggingService.debug('Avatar updated to: $avatarPath');
      } catch (e) {
        LoggingService.debug('Error updating avatar: $e');
      }
    }
  }

  Future<void> updateLocale(String locale) async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_currentUser!.id}_locale', locale);
      _currentUser = _currentUser!.copyWith(locale: locale);
    }
  }

  Future<void> updateUsername(String username) async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_currentUser!.id}_username', username);
      _currentUser = _currentUser!.copyWith(username: username);
    }
  }

  String _createNonce(int length) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<AuthUser?> signInWithApple() async {
    try {
      final rawNonce = _createNonce(32);
      final nonce = _sha256ofString(rawNonce);
      final prefs = await SharedPreferences.getInstance();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (credential.userIdentifier != null) {
        // Get existing user data if available
        final existingAvatarPath = prefs.getString('${credential.userIdentifier!}_avatar');
        final existingName = prefs.getString('${credential.userIdentifier!}_name');
        final existingUsername = prefs.getString('${credential.userIdentifier!}_username');
        
        final displayName = existingName ?? [
          credential.givenName,
          credential.familyName,
        ].whereType<String>().join(' ');

        _currentUser = AuthUser(
          id: credential.userIdentifier!,
          email: credential.email,
          name: displayName.isEmpty ? defaultUsername : displayName,
          avatarPath: existingAvatarPath,
          username: existingUsername,  // Add this
        );
        _isAuthenticated = true;
        await _saveUserData(_currentUser!);

        // Update CollectionService with new user
        final collectionService = await CollectionService.getInstance();
        await collectionService.setCurrentUser(credential.userIdentifier);

        // Initialize storage and start sync
        final storage = await StorageService.init(null);
        storage.startSync();

        // Save auth state
        _prefs?.setString('user_id', _currentUser!.id);
        _prefs?.setString('auth_token', _currentUser!.token ?? '');
        _prefs?.setString('user_data', jsonEncode(_currentUser!.toJson()));

        return _currentUser;
      }
      return null;
    } catch (e) {
      LoggingService.debug('Sign in with Apple error: $e');
      return null;
    }
  }

  Future<AuthUser?> signInWithGoogle() async {
    try {
      LoggingService.debug('🔍 AUTH: Starting Google authentication flow');
      
      // Make sure we clear any previous state
      _errorController.add(''); // Clear any previous errors
      
      // Get user from Google Auth Service
      LoggingService.debug('🔍 AUTH: Calling GoogleAuthService.signInWithGoogle');
      final user = await _googleAuthService.signInWithGoogle();
      LoggingService.debug('🔍 AUTH: GoogleAuthService returned ${user != null ? 'user' : 'null'}');
      
      if (user == null) {
        LoggingService.debug('🔍 AUTH: User cancelled Google sign-in or an error occurred');
        return null;
      }
      
      // Create or update user in your system
      LoggingService.debug('🔍 AUTH: Creating AuthUser from Google user');
      final authUser = AuthUser(
        id: user.uid,
        email: user.email,
        name: user.displayName,
        username: user.displayName ?? user.email?.split('@')[0],
        avatarPath: user.photoURL,
        authProvider: 'google',
      );
      
      LoggingService.debug('🔍 AUTH: Saving user data');
      await _saveUserData(authUser);
      
      // Set as current user
      _currentUser = authUser;
      _isAuthenticated = true;
      
      // Emit user changed event
      _authStateController.add(authUser);
      
      LoggingService.debug('🔍 AUTH: Google sign-in completed successfully');
      return authUser;
    } catch (e, stack) {
      LoggingService.error('🔍 AUTH: Error in signInWithGoogle: $e');
      LoggingService.debug('🔍 AUTH: Stack trace: $stack');
      _errorController.add('Failed to sign in with Google: ${e.toString()}');
      rethrow;
    }
  }

  // Update the direct sign-in method with Google credentials
  Future<AuthUser?> signInWithGoogleCredentials(
    String email, 
    String id, 
    String displayName, 
    String photoUrl,
    String accessToken,
    String idToken,
  ) async {
    try {
      LoggingService.debug('AuthService: Signing in with Google credentials for $email');
      
      // Create an AuthCredential with the Google tokens
      AuthCredential credential;
      try {
        credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );
      } catch (e) {
        LoggingService.debug('AuthService: Error creating credential: $e');
        // Continue with local auth as fallback
      }
      
      // Try Firebase Auth if credentials are available
      try {
        UserCredential? userCredential;
        try {
          userCredential = await FirebaseAuth.instance.signInWithCredential(
            GoogleAuthProvider.credential(
              accessToken: accessToken,
              idToken: idToken,
            )
          );
        } catch (e) {
          LoggingService.debug('AuthService: Firebase auth failed: $e');
        }
        
        if (userCredential?.user != null) {
          LoggingService.debug('AuthService: Firebase sign-in successful: ${userCredential!.user!.uid}');
          // Map to AuthUser
          final authUser = _mapFirebaseUserToAuthUser(userCredential.user!);
          
          // Set as current user and save
          _currentUser = authUser;
          _isAuthenticated = true;
          await _saveUserData(authUser);
          
          // Emit event
          _authStateController.add(authUser);
          
          return authUser;
        }
      } catch (e) {
        LoggingService.debug('AuthService: Error with Firebase auth: $e');
        // Continue with local auth
      }
      
      // Create local user as fallback
      LoggingService.debug('AuthService: Creating local user for Google account');
      final localUser = AuthUser(
        id: 'google_$id',
        email: email,
        name: displayName,
        avatarPath: photoUrl,
        locale: 'en',
        username: email.split('@').first,
        authProvider: 'google',
      );
      
      // Set as current user
      _currentUser = localUser;
      _isAuthenticated = true;
      
      // Save user data
      await _saveUserData(localUser);
      
      // Emit event
      _authStateController.add(localUser);
      
      LoggingService.debug('AuthService: Local Google user created successfully');
      return localUser;
    } catch (e) {
      LoggingService.error('AuthService: Error signing in with Google credentials: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      LoggingService.debug('AuthService: Starting sign-out process');
      final userId = _currentUser?.id;
      final authProvider = _currentUser?.authProvider;
      
      if (userId != null) {
        LoggingService.debug('AuthService: Signing out user: $userId with provider: $authProvider');
        
        // Clear user data from memory first
        _isAuthenticated = false;
        _currentUser = null;
        
        // Clear session state from services
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_id');
        
        try {
          // Handle provider-specific sign-out
          if (authProvider == 'google') {
            LoggingService.debug('AuthService: Performing Google sign-out');
            await _googleAuthService.signOut();
          } 
          // You can add other providers here if needed
        } catch (e) {
          // Log but don't fail - we want to continue with the rest of sign-out
          LoggingService.debug('AuthService: Error in provider-specific sign-out: $e');
        }
        
        // Always try to clear session state in services
        try {
          // Get collection service but don't fail if not available
          final collectionService = await CollectionService.getInstance();
          await collectionService?.clearSessionState();
          LoggingService.debug('AuthService: Cleared collection service session state');
        } catch (e) {
          LoggingService.debug('AuthService: Error clearing collection service state: $e');
        }
        
        try {
          // Get storage service but don't fail if not available
          final storage = await StorageService.init(null);
          await storage.clearSessionState();
          LoggingService.debug('AuthService: Cleared storage service session state');
        } catch (e) {
          LoggingService.debug('AuthService: Error clearing storage service session state: $e');
        }
        
        // Emit auth state change event
        _authStateController.add(null);
        
        LoggingService.debug('AuthService: Sign-out completed successfully');
      } else {
        LoggingService.debug('AuthService: No current user to sign out');
      }
    } catch (e) {
      LoggingService.debug('AuthService: Error during sign-out: $e');
      // Don't rethrow - we want the app to continue functioning even if sign-out fails
    }
  }

  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      final userId = _currentUser!.id;
      final prefs = await SharedPreferences.getInstance();
      
      // Actually delete all user data
      await prefs.remove('${userId}_email');
      await prefs.remove('${userId}_name');
      await prefs.remove('${userId}_avatar');
      await prefs.remove('${userId}_locale');
      await prefs.remove('${userId}_username');
      await prefs.remove('user_id');

      // Delete data from services
      final storage = await StorageService.init(null);
      await storage.permanentlyDeleteUserData();

      final collectionService = await CollectionService.getInstance();
      await collectionService.permanentlyDeleteUserData(userId);

      _isAuthenticated = false;
      _currentUser = null;
    }
  }

  Future<void> restoreAuthState() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    
    // Look for saved auth tokens/state
    final savedUserId = _prefs!.getString('user_id');
    
    if (savedUserId != null) {
      // Restore the user object from saved data
      try {
        final savedUserData = _prefs!.getString('${savedUserId}_data');
        if (savedUserData != null) {
          final userData = jsonDecode(savedUserData);
          _currentUser = AuthUser(
            id: savedUserId,
            email: _prefs!.getString('${savedUserId}_email'),
            name: _prefs!.getString('${savedUserId}_name') ?? 'Pokemon Trainer',
            avatarPath: _prefs!.getString('${savedUserId}_avatar'),
            locale: _prefs!.getString('${savedUserId}_locale') ?? 'en',
            username: _prefs!.getString('${savedUserId}_username'),
            token: _prefs!.getString('auth_token'),
            authProvider: _prefs!.getString('${savedUserId}_authProvider') ?? 'apple', // Add authProvider with default
          );
          _isAuthenticated = true;
          
          // The critical fix - make sure storage service gets the ID
          final storage = await StorageService.init(null);
          storage.setCurrentUser(savedUserId);
          
          LoggingService.debug('Auth state restored for user: $savedUserId');
        }
      } catch (e) {
        LoggingService.debug('Error restoring user data: $e');
      }
    } else {
      LoggingService.debug('No saved user ID found during auth restore');
    }
  }
  
  // Make sure to close controllers when not needed
  void dispose() {
    _authStateController.close();
    _errorController.close();
  }
  
  // Add method to help with saving user to database (referenced but not implemented)
  Future<void> _saveUserToDatabase(AuthUser user) async {
    // This would typically connect to a database service
    // For now, we'll just use local storage via _saveUserData
    await _saveUserData(user);
    LoggingService.debug('User saved to local database: ${user.id}');
  }

  // Add the missing function to map Firebase User to AuthUser
  AuthUser _mapFirebaseUserToAuthUser(User firebaseUser) {
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      name: firebaseUser.displayName,
      avatarPath: firebaseUser.photoURL,
      locale: 'en',
      authProvider: 'google',
    );
  }

  // Add method to save debug user data
  Future<void> saveDebugUserData(AuthUser debugUser) async {
    LoggingService.debug('🐞 DEBUG: Saving debug user data');
    
    _currentUser = debugUser;
    _isAuthenticated = true;
    await _saveUserData(debugUser);
    
    // Emit user changed event
    _authStateController.add(debugUser);
    
    LoggingService.debug('🐞 DEBUG: Debug user data saved');
  }
}

class AuthUser {
  final String id;
  final String? email;
  final String? name;
  final String? avatarPath;
  final String? locale;
  final String? username;
  final String? token;
  final String? authProvider; // Add this new field

  AuthUser({
    required this.id,
    this.email,
    this.name,
    this.avatarPath,
    this.locale = 'en',
    this.username,
    this.token,
    this.authProvider, // Add to constructor
  });

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarPath,
    String? locale,
    String? username,
    String? token,
    String? authProvider, // Add to copyWith
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      locale: locale ?? this.locale,
      username: username ?? this.username,
      token: token ?? this.token,
      authProvider: authProvider ?? this.authProvider, // Include in copyWith
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarPath': avatarPath,
      'locale': locale,
      'username': username,
      'token': token,
      'authProvider': authProvider, // Include in JSON
    };
  }

  static AuthUser fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatarPath: json['avatarPath'],
      locale: json['locale'] ?? 'en',
      username: json['username'],
      token: json['token'],
      authProvider: json['authProvider'], // Include in fromJson
    );
  }
}
