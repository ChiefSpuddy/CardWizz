import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Fix the import
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/collection_service.dart';  // Add this import

class AppState with ChangeNotifier {
  final StorageService _storageService;
  final AuthService _authService;
  CollectionService? _collectionService;
  SharedPreferences? _prefs;  // Add this
  bool _isDarkMode = true;  // Change default to true
  bool _isLoading = true;
  Locale _locale = const Locale('en');
  bool _analyticsEnabled = true;
  bool _searchHistoryEnabled = true;
  bool _profileVisible = false;
  bool _showPrices = true;

  AppState(this._storageService, this._authService);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _prefs = await SharedPreferences.getInstance();  // Initialize prefs
    await _authService.initialize();
    _collectionService = await CollectionService.getInstance();
    
    if (_authService.isAuthenticated) {
      _storageService.setCurrentUser(_authService.currentUser!.id);
      _collectionService?.setCurrentUser(_authService.currentUser!.id);
    }
    
    // Load dark mode setting, default to true if not set
    _isDarkMode = _prefs?.getBool('darkMode') ?? true;

    await _initializePrivacySettings();

    _isLoading = false;
    notifyListeners();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authService.isAuthenticated;
  AuthUser? get currentUser => _authService.currentUser;
  Locale get locale => _locale;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get searchHistoryEnabled => _searchHistoryEnabled;
  bool get profileVisible => _profileVisible;
  bool get showPrices => _showPrices;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs?.setBool('darkMode', _isDarkMode);
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

  Future<void> setAnalyticsEnabled(bool value) async {
    _analyticsEnabled = value;
    await _storageService.setBool('analytics_enabled', value);
    notifyListeners();
  }

  Future<void> setSearchHistoryEnabled(bool value) async {
    _searchHistoryEnabled = value;
    await _storageService.setBool('search_history_enabled', value);
    notifyListeners();
  }

  Future<void> setProfileVisibility(bool value) async {
    _profileVisible = value;
    await _storageService.setBool('profile_visible', value);
    notifyListeners();
  }

  Future<void> setShowPrices(bool value) async {
    _showPrices = value;
    await _storageService.setBool('show_prices', value);
    notifyListeners();
  }

  Future<void> exportUserData() async {
    // Implement export functionality
    // This could generate a JSON file with user's data
    final userData = await _storageService.exportUserData();
    // Implement file saving logic here
  }

  Future<void> clearSearchHistory() async {
    await _storageService.clearSearchHistory();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    try {
      // Delete user data from storage
      await _storageService.clearAllData();
      
      // Sign out user
      await signOut();
      
      // Delete authentication data
      await _authService.deleteAccount();
      
      notifyListeners();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> _initializePrivacySettings() async {
    _analyticsEnabled = await _storageService.getBool('analytics_enabled') ?? true;
    _searchHistoryEnabled = await _storageService.getBool('search_history_enabled') ?? true;
    _profileVisible = await _storageService.getBool('profile_visible') ?? false;
    _showPrices = await _storageService.getBool('show_prices') ?? true;
  }

  Future<bool> verifyPrivacySettings() async {
    // Verify current state matches stored preferences
    final storedAnalytics = await _storageService.getBool('analytics_enabled') ?? true;
    final storedSearchHistory = await _storageService.getBool('search_history_enabled') ?? true;
    final storedProfileVisible = await _storageService.getBool('profile_visible') ?? false;
    final storedShowPrices = await _storageService.getBool('show_prices') ?? true;

    return storedAnalytics == _analyticsEnabled &&
           storedSearchHistory == _searchHistoryEnabled &&
           storedProfileVisible == _profileVisible &&
           storedShowPrices == _showPrices;
  }

  static const supportedLocales = [
    Locale('en'), // English
    Locale('es'), // Spanish
    Locale('ja'), // Japanese
    // Add more supported locales
  ];
}
