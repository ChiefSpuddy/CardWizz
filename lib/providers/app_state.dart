import '../services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/collection_service.dart';
import '../services/navigation_service.dart';  // Add this import
import 'theme_provider.dart';  // Import our theme provider
import 'dart:async'; // Add this for Timer

class AppState with ChangeNotifier {
  final StorageService _storageService;
  final AuthService _authService;
  CollectionService? _collectionService;
  SharedPreferences? _prefs;  // Add this
  bool _isLoading = true;
  Locale _locale = const Locale('en');
  bool _analyticsEnabled = true;
  bool _searchHistoryEnabled = true;
  bool _profileVisible = false;
  bool _showPrices = true;
  DateTime? _lastCardChangeTime;
  Timer? _debounceTimer;

  AppState(this._storageService, this._authService);

  // Optimize the initialize method:
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load preferences first - quick operation
      _prefs = await SharedPreferences.getInstance();
      
      // Handle auth state restoration - critical for startup
      await _authService.restoreAuthState();
      
      // Initialize storage in a separate microtask to avoid blocking UI
      if (_authService.isAuthenticated && _authService.currentUser != null) {
        final userId = _authService.currentUser!.id;
        LoggingService.debug('AppState: Initializing with authenticated user: $userId');
        
        // Set user ID in storage service
        _storageService.setCurrentUser(userId);
        
        // Load collection service in background
        _initializeCollectionServiceAsync(userId);
      } else {
        LoggingService.debug('AppState: No authenticated user found');
      }
      
      // Initialize these settings in background
      Future.microtask(() => _initializePrivacySettings());
    } catch (e) {
      LoggingService.debug('AppState initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this helper method to move work to background
  Future<void> _initializeCollectionServiceAsync(String userId) async {
    try {
      // Get collection service instance
      _collectionService = await CollectionService.getInstance();
      
      // Set user ID
      await _collectionService?.setCurrentUser(userId);
      
      // Refresh state in background
      Future.delayed(
        const Duration(milliseconds: 300),
        () => _storageService.refreshState(),
      );
      
      LoggingService.debug('AppState: Collection service initialized successfully');
    } catch (e) {
      LoggingService.debug('AppState: Error initializing collection service: $e');
    }
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authService.isAuthenticated;
  AuthUser? get currentUser => _authService.currentUser;
  Locale get locale => _locale;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get searchHistoryEnabled => _searchHistoryEnabled;
  bool get profileVisible => _profileVisible;
  bool get showPrices => _showPrices;

  // Delegate theme toggle to ThemeProvider
  void toggleTheme() {
    // This is just a pass-through method to maintain compatibility
    // with existing code that calls appState.toggleTheme()
    
    // We'll find the ThemeProvider and call its toggleTheme method
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.toggleTheme();
    }
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
      LoggingService.debug('Signed in user: ${user.id}');
    }
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    final userId = _authService.currentUser?.id;
    if (userId != null) {
      LoggingService.debug('Signing out user: $userId');
      // Just clear session state without deleting data
      await _storageService.clearSessionState();
      await _collectionService?.clearSessionState();
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
      await _authService.deleteAccount();
      // Change clearUserData to permanentlyDeleteUserData
      await _storageService.permanentlyDeleteUserData();
      notifyListeners();
    } catch (e) {
      LoggingService.debug('Error deleting account: $e');
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

  // Find the notifyCardChange method and modify it to prevent navigation issues
  // Add forceNavigate parameter with default true for backward compatibility
  void notifyCardChange({bool forceNavigate = true}) {
    // Record the time of change for debouncing
    _lastCardChangeTime = DateTime.now();
    
    // Notify listeners of the change
    notifyListeners();
    
    // Only trigger navigation if explicitly requested
    if (forceNavigate) {
      // Your existing navigation code here if any
    }
  }

  // Add this debounce helper
  Timer? _cardChangeDebouncer;
  void _debounceCardChange(VoidCallback callback) {
    // Cancel previous timer if active
    if (_cardChangeDebouncer?.isActive ?? false) {
      _cardChangeDebouncer!.cancel();
    }
    
    // Create new timer with the callback
    _cardChangeDebouncer = Timer(const Duration(milliseconds: 300), callback);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
