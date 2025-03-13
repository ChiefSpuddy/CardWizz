import 'package:shared_preferences/shared_preferences.dart';  // Fixed import
import '../services/purchase_service.dart';
import 'package:flutter/foundation.dart';

class PremiumService extends ChangeNotifier {
  final PurchaseService _purchaseService;
  final SharedPreferences _prefs;
  static const String _premiumStatusKey = 'premium_status';
  
  // Add debug override properties
  bool _debugOverrideEnabled = false;
  bool _debugPremiumStatus = false;

  PremiumService(this._purchaseService, this._prefs);

  bool get isPremium => _debugOverrideEnabled ? _debugPremiumStatus : (_prefs.getBool(_premiumStatusKey) ?? false);
  
  // Debug mode getters and setters
  bool get isDebugOverrideEnabled => _debugOverrideEnabled;
  bool get debugPremiumStatus => _debugPremiumStatus;
  
  // Toggle debug override
  void setDebugOverride(bool enabled, {bool premiumStatus = false}) {
    _debugOverrideEnabled = enabled;
    _debugPremiumStatus = premiumStatus;
    notifyListeners();
  }
  
  // Reset to actual subscription state
  void resetDebugOverride() {
    _debugOverrideEnabled = false;
    notifyListeners();
  }

  // Premium feature flags
  bool get hasUnlimitedCollections => isPremium;
  bool get hasAdvancedAnalytics => isPremium;
  bool get hasPriceAlerts => isPremium;
  bool get hasBackupRestore => isPremium;
  bool get hasCustomThemes => isPremium;
  bool get hasCardScanning => isPremium;
  bool get hasBulkImport => isPremium;
  bool get hasMarketData => isPremium;

  // Feature limits for free users
  static const int maxFreeCards = 200;  // Changed from 100
  static const int maxFreeCollections = 4;  // Changed from 3
  static const int maxFreeAlerts = 2;

  Future<bool> upgradeToPremium() async {
    try {
      // Store the previous premium status
      final wasPremium = isPremium;
      
      // Call the purchase method (which may return void)
      await _purchaseService.purchasePremium();
      
      // Check if premium status changed or is now true
      final isPremiumNow = _purchaseService.isPremium;
      final success = isPremiumNow && !wasPremium;
      
      if (isPremiumNow) {
        // Save the premium status
        await _prefs.setBool(_premiumStatusKey, true);
        
        // If debug mode is on, disable it since we have a real purchase
        if (_debugOverrideEnabled) {
          resetDebugOverride();
        }
        
        notifyListeners();
      }
      
      return isPremiumNow;
    } catch (e) {
      return false;
    }
  }

  bool canAddMoreCards(int currentCount) {
    if (isPremium) return true;
    return currentCount < maxFreeCards;
  }

  bool canCreateCollection(int currentCollections) {
    if (isPremium) return true;
    return currentCollections < maxFreeCollections;
  }

  bool canCreatePriceAlert(int currentAlerts) {
    if (isPremium) return true;
    return currentAlerts < maxFreeAlerts;
  }
}
