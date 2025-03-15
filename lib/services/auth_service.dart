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
      final user = await _googleAuthService.signInWithGoogle();
      
      if (user == null) return null;
      
      // Create or update user in your system
      final authUser = AuthUser(
        id: user.uid,
        email: user.email,
        name: user.displayName,
        // Set username from email initially or null
        username: user.displayName ?? user.email?.split('@')[0],
        // Use Google profile photo if available
        avatarPath: user.photoURL,
        authProvider: 'google', // Specify auth provider
      );
      
      // Save user data
      await _saveUserData(authUser);
      
      // Set as current user
      _currentUser = authUser;
      _isAuthenticated = true;
      
      // Emit user changed event
      _authStateController.add(authUser);
      
      return authUser;
    } catch (e) {
      _errorController.add('Failed to sign in with Google: ${e.toString()}');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      // Check if the current user is signed in with Google
      final currentUser = _currentUser;
      if (currentUser?.authProvider == 'google') {
        await _googleAuthService.signOut();
      } else {
        // Handle other sign out methods
        if (_currentUser != null) {
          final prefs = await SharedPreferences.getInstance();
          // Only remove the active session marker
          await prefs.remove('user_id');

          // Just clear current session state without deleting any data
          final collectionService = await CollectionService.getInstance();
          await collectionService.clearSessionState();  // This only clears in-memory state

          final storage = await StorageService.init(null);
          await storage.clearSessionState();  // This only clears in-memory state

          _isAuthenticated = false;
          _currentUser = null;
        }
      }
      
      // Clear current user
      _currentUser = null;
      _authStateController.add(null);
      
    } catch (e) {
      _errorController.add('Failed to sign out: ${e.toString()}');
      rethrow;
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
