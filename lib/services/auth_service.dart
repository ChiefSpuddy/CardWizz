import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../services/collection_service.dart';  // Add this import
// Add this import for String.characters
import 'package:characters/characters.dart';

class AuthService {
  static const defaultUsername = 'Pokemon Trainer';
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  AuthUser? _currentUser;

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
        email: prefs.getString('user_email'),
        name: prefs.getString('user_name'),
        avatarPath: prefs.getString('user_avatar'),
      );
      
      // Initialize CollectionService with saved user ID
      final collectionService = await CollectionService.getInstance();
      await collectionService.setCurrentUser(savedUserId);
    }
    _isInitialized = true;
  }

  Future<void> _saveUserData(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('${user.id}_email', user.email ?? '');
    await prefs.setString('${user.id}_name', user.name ?? '');
    if (user.avatarPath != null) {
      await prefs.setString('${user.id}_avatar', user.avatarPath!);
    }
  }

  Future<void> updateAvatar(String avatarPath) async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_currentUser!.id}_avatar', avatarPath);
      _currentUser = _currentUser!.copyWith(avatarPath: avatarPath); // Add this method to AuthUser
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
        
        final displayName = existingName ?? [
          credential.givenName,
          credential.familyName,
        ].whereType<String>().join(' ');

        _currentUser = AuthUser(
          id: credential.userIdentifier!,
          email: credential.email,
          name: displayName,
          avatarPath: existingAvatarPath,
        );
        _isAuthenticated = true;
        await _saveUserData(_currentUser!);

        // Update CollectionService with new user
        final collectionService = await CollectionService.getInstance();
        await collectionService.setCurrentUser(credential.userIdentifier);

        return _currentUser;
      }
      return null;
    } catch (e) {
      print('Sign in with Apple error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_avatar');  // Add this line

    // Clear CollectionService user
    final collectionService = await CollectionService.getInstance();
    await collectionService.setCurrentUser(null);

    _isAuthenticated = false;
    _currentUser = null;
  }
}

class AuthUser {
  final String id;
  final String? email;
  final String? name;
  final String? avatarPath;

  AuthUser({
    required this.id,
    this.email,
    this.name,
    this.avatarPath,
  });

  // Add this method
  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarPath,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
