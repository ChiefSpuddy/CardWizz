import '../services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/collection_service.dart';
import '../services/navigation_service.dart';
import 'theme_provider.dart';
import 'dart:async';

class AppState with ChangeNotifier {
  final StorageService _storageService;
  final AuthService _authService;
  CollectionService? _collectionService;
  SharedPreferences? _prefs;
  bool _isLoading = true;
  Locale _locale = const Locale('en');
  bool _analyticsEnabled = true;
  bool _searchHistoryEnabled = true;
  bool _profileVisible = false;
  bool _showPrices = true;
  DateTime? _lastCardChangeTime;
  Timer? _debounceTimer;
  
  final StreamController<AuthUser?> _authStateController = StreamController<AuthUser?>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

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

  // Update the signInWithGoogle method to be more robust
  Future<AuthUser?> signInWithGoogle() async {
    try {
      LoggingService.debug('🔍 GOOGLE: Starting Google Sign-In flow');
      
      // Simply call the auth service method
      final user = await _authService.signInWithGoogle();
      LoggingService.debug('🔍 GOOGLE: Auth service returned user: ${user != null}');
      
      if (user != null) {
        LoggingService.debug('🔍 GOOGLE: Processing successful sign-in');
        await _handleSuccessfulSignIn(user);
        await _storageService.setString('auth_provider', 'google');
        LoggingService.debug('🔍 GOOGLE: Sign-in process complete');
      } else {
        LoggingService.debug('🔍 GOOGLE: Sign-in cancelled or returned null');
      }
      
      return user;
    } catch (e, stack) {
      // Log with stack trace
      LoggingService.error('🔍 GOOGLE: Error in signInWithGoogle: $e');
      LoggingService.debug('🔍 GOOGLE: Stack trace: $stack');
      _handleAuthError('Google Sign-In failed: $e');
      rethrow;
    }
  }

  // Add the missing method to handle successful sign-in
  Future<void> _handleSuccessfulSignIn(AuthUser user) async {
    try {
      // Wait a moment to allow system to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Set the current user in storage service
      _storageService.setCurrentUser(user.id);
      
      // Set user in collection service if available
      if (_collectionService != null) {
        await _collectionService!.setCurrentUser(user.id);
      } else {
        _collectionService = await CollectionService.getInstance();
        await _collectionService?.setCurrentUser(user.id);
      }
      
      // Notify listeners about authentication change
      _authStateController.add(user);
      notifyListeners();
      
      LoggingService.debug('Successfully signed in user: ${user.id}');
    } catch (e) {
      _handleAuthError('Failed to complete sign-in process: $e');
    }
  }
  
  // Fix this method to use the correct LoggingService.error signature
  void _handleAuthError(String errorMessage) {
    // The error is here - LoggingService.error only accepts one argument
    // or uses named parameter 'error:' - check the implementation
    LoggingService.error('Authentication error: $errorMessage');
    _errorController.add(errorMessage);
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      LoggingService.debug('AppState: Starting sign-out process');
      
      // Cancel any pending operations that might trigger callbacks
      _debounceTimer?.cancel();
      
      // Notify listeners BEFORE sign-out to update UI
      notifyListeners();
      
      // Attempt to sign out regardless of current state
      await _authService.signOut();
      
      // Clear local state
      await _storageService.clearSessionState();
      
      // Navigation must happen AFTER all state is cleared
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        LoggingService.debug('AppState: Navigating to sign-in screen');
        
        // Use a slight delay to ensure all cleanup is complete before navigation
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Check if context is still valid after the delay
        if (NavigationService.navigatorKey.currentContext != null) {
          // Clear navigation stack and go to root/home screen
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          LoggingService.debug('AppState: Context is no longer valid after delay');
        }
      } else {
        LoggingService.debug('AppState: Could not navigate - no current context');
      }
      
      LoggingService.debug('AppState: Sign-out completed');
    } catch (e) {
      LoggingService.debug('AppState: Error during sign-out: $e');
      
      // Try to navigate anyway if there was an error
      try {
        final context = NavigationService.navigatorKey.currentContext;
        if (context != null) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (navError) {
        LoggingService.debug('AppState: Error during navigation after sign-out: $navError');
      }
    }
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

  // Enhance the signInWithGoogleCredentials method - fixed duplicate method and references to _isAuthenticated
  Future<AuthUser?> signInWithGoogleCredentials(
    String email, 
    String id, 
    String displayName, 
    String photoUrl,
    String accessToken,
    String idToken,
  ) async {
    try {
      LoggingService.debug('🔍 GOOGLE CREDS: Processing Google credentials for $email');
      
      // Use the auth service to sign in with the provided credentials
      final user = await _authService.signInWithGoogleCredentials(
        email, 
        id, 
        displayName, 
        photoUrl,
        accessToken,
        idToken,
      );
      
      if (user != null) {
        LoggingService.debug('🔍 GOOGLE CREDS: Auth service returned valid user: ${user.id}');
        
        // Handle successful sign-in
        await _handleSuccessfulSignIn(user);
        
        // Save provider info
        await _storageService.setString('auth_provider', 'google');
        
        // CRITICAL FIX: Make sure authentication state is properly detected
        LoggingService.debug('🔍 GOOGLE CREDS: Authentication state - isAuthenticated: ${_authService.isAuthenticated}');
        
        // Force authentication check if it's not set
        if (!_authService.isAuthenticated) {
          LoggingService.debug('🔍 GOOGLE CREDS: Auth service shows not authenticated, but we have a user');
          // No need to manually set isAuthenticated as it's managed by AuthService
          // Just notify listeners to update UI
          notifyListeners();
        }
        
        return user;
      } else {
        LoggingService.debug('🔍 GOOGLE CREDS: Auth service returned null user');
        return null;
      }
    } catch (e, stack) {
      LoggingService.error('🔍 GOOGLE CREDS: Error in signInWithGoogleCredentials: $e');
      LoggingService.debug('🔍 GOOGLE CREDS: Stack trace: $stack');
      rethrow;
    }
  }

  // Add a debug method for testing authentication without Google Sign-In
  Future<AuthUser?> signInWithDebugAccount({
    required String email,
    required String displayName,
  }) async {
    try {
      LoggingService.debug('🐞 DEBUG: Creating debug user account');
      
      // Generate a unique ID for this debug session
      final uniqueId = 'debug_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create a mock AuthUser
      final debugUser = AuthUser(
        id: uniqueId,
        email: email,
        name: displayName,
        username: displayName.split(' ').first.toLowerCase(),
        authProvider: 'debug',
      );
      
      // Save the user data
      await _authService.saveDebugUserData(debugUser);
      
      // Handle sign-in process
      await _handleSuccessfulSignIn(debugUser);
      
      LoggingService.debug('🐞 DEBUG: Successfully created debug user: $uniqueId');
      return debugUser;
    } catch (e) {
      LoggingService.error('🐞 DEBUG: Error creating debug user: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _authStateController.close();
    _errorController.close();
    super.dispose();
  }
}
