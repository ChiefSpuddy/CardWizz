import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'purchase_service.dart';
import '../services/logging_service.dart';

class PremiumService extends ChangeNotifier {
  final PurchaseService _purchaseService;
  final SharedPreferences _prefs;
  static PremiumService? _instance;
  
  bool _isPremiumOverride = false;
  bool _isDebugOverride = false;
  bool _debugPremiumStatus = false;
  
  // Private constructor
  PremiumService._(this._purchaseService, this._prefs) {
    // Initialize with current purchase service state
    _updateFromPurchaseService();
    
    // Listen for changes to purchase state
    _purchaseService.addListener(_updateFromPurchaseService);
    
    // Restore debug override settings from prefs if they exist
    _isDebugOverride = _prefs.getBool('debug_override_enabled') ?? false;
    _debugPremiumStatus = _prefs.getBool('debug_premium_status') ?? false;
    
    LoggingService.debug('PremiumService initialized, debug override: $_isDebugOverride');
  }
  
  // Static factory method that ensures a singleton instance
  static Future<PremiumService> initialize(
    PurchaseService purchaseService,
    SharedPreferences prefs
  ) async {
    if (_instance == null) {
      _instance = PremiumService._(purchaseService, prefs);
      LoggingService.debug('PremiumService initialized');
    }
    return _instance!;
  }
  
  // Static getter for the instance
  static PremiumService? get instance => _instance;
  
  void _updateFromPurchaseService() {
    // Check if we should update
    final newStatus = _purchaseService.isPremium;
    if (newStatus != _lastKnownPremiumStatus) {
      _lastKnownPremiumStatus = newStatus;
      notifyListeners();
    }
  }
  
  bool _lastKnownPremiumStatus = false;
  
  // Premium status getter that considers purchase service state and override
  bool get isPremium {
    if (_isDebugOverride) {
      return _debugPremiumStatus;
    }
    return _isPremiumOverride || _purchaseService.isPremium;
  }
  
  // For debugging/development only
  void setIsPremiumOverride(bool value) {
    if (_isPremiumOverride != value) {
      _isPremiumOverride = value;
      LoggingService.debug('Premium override set to: $value');
      notifyListeners();
    }
  }
  
  // Debug override getters and setters
  bool get isDebugOverrideEnabled => _isDebugOverride;
  
  // Debug override methods
  void setDebugOverride(bool enabled, {required bool premiumStatus}) {
    _isDebugOverride = enabled;
    _debugPremiumStatus = premiumStatus;
    
    // Save debug settings
    _prefs.setBool('debug_override_enabled', enabled);
    _prefs.setBool('debug_premium_status', premiumStatus);
    
    LoggingService.debug(
      'Debug override set to: $enabled, premium status: $premiumStatus'
    );
    
    notifyListeners();
  }
  
  // Reset debug override
  void resetDebugOverride() {
    _isDebugOverride = false;
    _prefs.setBool('debug_override_enabled', false);
    
    LoggingService.debug('Debug override reset');
    notifyListeners();
  }
  
  // Feature-specific premium checks
  bool canAccessFeature(String feature) {
    return isPremium || _isFeatureAvailableForFree(feature);
  }
  
  bool _isFeatureAvailableForFree(String feature) {
    // Define which features are available in free tier
    switch (feature) {
      case 'basic_collection':
      case 'basic_search':
        return true;
      default:
        return false;
    }
  }
  
  // Cleanup
  @override
  void dispose() {
    _purchaseService.removeListener(_updateFromPurchaseService);
    super.dispose();
  }
}
