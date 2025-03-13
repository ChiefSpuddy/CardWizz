import 'dart:async';
import '../providers/app_state.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class InitializationService {
  // Status reporting
  final _progressController = StreamController<double>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  
  // Expose streams
  Stream<double> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;
  
  // Completion flag
  final _isInitialized = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isInitialized => _isInitialized;
  
  // Required services
  final StorageService _storageService;
  final AppState _appState;
  final AuthService _authService;
  
  // Add minimum display time to ensure loading screen is visible
  static const Duration minLoadingDisplayTime = Duration(milliseconds: 1500);
  DateTime? _initStartTime;
  
  InitializationService(
    this._storageService,
    this._appState,
    this._authService,
  );
  
  Future<void> initialize() async {
    _initStartTime = DateTime.now();
    
    try {
      // Stage 1: Core services
      _updateProgress(0.1, 'Starting up...');
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Stage 2: User authentication
      _updateProgress(0.3, 'Checking login status...');
      await _authService.restoreAuthState();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Stage 3: App state initialization
      _updateProgress(0.5, 'Loading your collection...');
      await _appState.initialize();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Stage 4: Load user data
      _updateProgress(0.7, 'Preparing your cards...');
      if (_authService.isAuthenticated) {
        // Pre-load essential data
        await _storageService.refreshCards();
        // Don't wait for full initialization of non-critical components
        _preloadNonCriticalData();
      }
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Stage 5: Final preparations
      _updateProgress(0.9, 'Almost ready...');
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Complete
      _updateProgress(1.0, 'Ready!');
      
      // Make sure we show the loading screen for at least minLoadingDisplayTime
      await _ensureMinimumLoadingTime();
      
      // Mark initialization as complete
      _isInitialized.value = true;
      
    } catch (e, stackTrace) {
      AppLogger.e('Initialization error: $e', error: e, stackTrace: stackTrace);
      _statusController.add('Error during startup: $e');
      
      // Still need to complete after error, but show error message
      await _ensureMinimumLoadingTime();
      _isInitialized.value = true;
    }
  }
  
  // This ensures the loading screen is shown for at least the minimum time
  // to avoid flashing screens and provide better UX
  Future<void> _ensureMinimumLoadingTime() async {
    if (_initStartTime != null) {
      final elapsedTime = DateTime.now().difference(_initStartTime!);
      final remainingTime = minLoadingDisplayTime - elapsedTime;
      
      if (remainingTime.isNegative) {
        return;
      }
      
      AppLogger.d('Waiting for ${remainingTime.inMilliseconds}ms to ensure minimum loading time', tag: 'Init');
      await Future.delayed(remainingTime);
    }
  }
  
  // Load non-critical data in the background without blocking the UI
  void _preloadNonCriticalData() {
    Future.microtask(() async {
      try {
        // Add any background data loading here that shouldn't block the UI
        // For example: prefetching images, caching data, etc.
      } catch (e) {
        AppLogger.e('Error preloading data: $e', error: e);
      }
    });
  }
  
  void _updateProgress(double progress, String status) {
    _progressController.add(progress);
    _statusController.add(status);
    AppLogger.d('App Initialization: $status ($progress)', tag: 'Init');
  }
  
  void dispose() {
    _progressController.close();
    _statusController.close();
    _isInitialized.dispose();
  }
}
