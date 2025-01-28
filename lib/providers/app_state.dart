import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/collection_service.dart';  // Add this import

class AppState with ChangeNotifier {
  final StorageService _storageService;
  final AuthService _authService;
  CollectionService? _collectionService;  // Add this
  bool _isDarkMode = false;
  bool _isLoading = true;
  Locale _locale = const Locale('en');

  AppState(this._storageService, this._authService);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _authService.initialize();
    _collectionService = await CollectionService.getInstance();  // Add this
    
    if (_authService.isAuthenticated) {
      _storageService.setCurrentUser(_authService.currentUser!.id);
      _collectionService?.setCurrentUser(_authService.currentUser!.id);
    }
    
    final darkMode = await _storageService.getBool('darkMode');
    _isDarkMode = darkMode ?? false;

    _isLoading = false;
    notifyListeners();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authService.isAuthenticated;
  AuthUser? get currentUser => _authService.currentUser;
  Locale get locale => _locale;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    if (_authService.currentUser != null) {
      await _authService.updateLocale(languageCode);
    }
    await _storageService.setString('languageCode', languageCode);
    notifyListeners();
  }

  Future<AuthUser?> signInWithApple() async {
    final user = await _authService.signInWithApple();
    if (user != null) {
      // Use proper async/await
      await Future.delayed(const Duration(milliseconds: 100));
      _storageService.setCurrentUser(user.id);
      if (_collectionService != null) {
        _collectionService!.setCurrentUser(user.id);
      }
      print('Signed in user: ${user.id}');
    }
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      print('Signing out user: $userId');
      // Clear in correct order
      await _storageService.clearUserData();
      await _collectionService?.clearUserData();
      await _authService.signOut();
    }
    notifyListeners();
  }

  Future<void> updateAvatar(String avatarPath) async {
    await _authService.updateAvatar(avatarPath);
    // Use more specific notification
    notifyListeners();
  }

  Future<void> updateUsername(String username) async {
    await _authService.updateUsername(username);
    // Use more specific notification
    notifyListeners();
  }

  static const supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('ja'), // Japanese
    // Add more supported locales
  ];
}
