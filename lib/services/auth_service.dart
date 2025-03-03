import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../services/collection_service.dart';
import '../services/storage_service.dart';  // Add this import
import 'package:characters/characters.dart';

class AuthService {
  static const defaultUsername = 'Pokemon Trainer';
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  AuthUser? _currentUser;
  SharedPreferences? _prefs;

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get currentUser => _currentUser;

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
        locale: prefs.getString('${savedUserId}_locale') ?? 'en',  // Add this
        username: prefs.getString('${savedUserId}_username'),  // Add this
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_currentUser!.id}_avatar', avatarPath);
      _currentUser = _currentUser!.copyWith(avatarPath: avatarPath); // Add this method to AuthUser
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
      print('Sign in with Apple error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
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
          );
          _isAuthenticated = true;
          
          // The critical fix - make sure storage service gets the ID
          final storage = await StorageService.init(null);
          storage.setCurrentUser(savedUserId);
          
          print('Auth state restored for user: $savedUserId');
        }
      } catch (e) {
        print('Error restoring user data: $e');
      }
    } else {
      print('No saved user ID found during auth restore');
    }
  }
}

class AuthUser {
  final String id;
  final String? email;
  final String? name;
  final String? avatarPath;
  final String locale;  // Add this
  final String? username;  // Add this
  final String? token; // Add this property

  AuthUser({
    required this.id,
    this.email,
    this.name,
    this.avatarPath,
    this.locale = 'en',  // Default to English
    this.username,  // Add this
    this.token, // Add this parameter
  });

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarPath,
    String? locale,
    String? username,  // Add this
    String? token, // Add this parameter
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      locale: locale ?? this.locale,
      username: username ?? this.username,  // Add this
      token: token ?? this.token, // Add this field
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
      'token': token, // Add this field
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
      token: json['token'], // Add this field
    );
  }
}
